
import SwiftUI

struct KnowledgeGraphView: View {
    @StateObject private var viewModel = KnowledgeGraphViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMemo: Memo?
    @State private var showingMemoDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("グラフを生成中...")
                } else if let graphData = viewModel.graphData {
                    if graphData.nodes.isEmpty {
                        emptyStateView
                    } else {
                        graphView(graphData: graphData)
                    }
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("ナレッジグラフ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // デモモード切り替え
                        Button {
                            viewModel.toggleDemoMode()
                        } label: {
                            Image(systemName: viewModel.useDemoData ? "wand.and.stars" : "network")
                        }
                        
                        // ズームリセット
                        Button {
                            viewModel.resetZoom()
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadGraph()
            }
            .sheet(isPresented: $showingMemoDetail) {
                if let memo = selectedMemo {
                    NavigationView {
                        MemoDetailView(memo: memo)
                    }
                }
            }
        }
    }
    
    private func graphView(graphData: GraphData) -> some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            // グラフの境界を計算
            let minX = graphData.nodes.map { $0.position.x }.min() ?? 0
            let maxX = graphData.nodes.map { $0.position.x }.max() ?? screenWidth
            let minY = graphData.nodes.map { $0.position.y }.min() ?? 0
            let maxY = graphData.nodes.map { $0.position.y }.max() ?? screenHeight
            
            let graphWidth = maxX - minX + 100  // マージン追加
            let graphHeight = maxY - minY + 100
            
            // 画面に収まるスケールを計算
            let scaleX = screenWidth / graphWidth
            let scaleY = screenHeight / graphHeight
            let autoScale = min(scaleX, scaleY, 1.0)
            
            // グラフ中心を画面中心に配置するオフセット
            let graphCenterX = (minX + maxX) / 2
            let graphCenterY = (minY + maxY) / 2
            let screenCenterX = screenWidth / 2
            let screenCenterY = screenHeight / 2
            let autoOffsetX = (screenCenterX - graphCenterX * autoScale)
            let autoOffsetY = (screenCenterY - graphCenterY * autoScale)
            
            ZStack {
                // 背景
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // デバッグ情報（開発時のみ表示）
                VStack {
                    HStack {
                        Text("ノード: \(graphData.nodes.count)")
                            .font(.caption)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        Text("エッジ: \(graphData.edges.count)")
                            .font(.caption)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
                .zIndex(100)
                
                // グラフキャンバス
                Canvas { context, size in
                    // エッジを描画
                    for edge in graphData.edges {
                        guard let sourceNode = graphData.nodes.first(where: { $0.id == edge.sourceId }),
                              let targetNode = graphData.nodes.first(where: { $0.id == edge.targetId }) else {
                            continue
                        }
                        
                        let isHighlighted = viewModel.selectedNodeId == edge.sourceId ||
                                          viewModel.selectedNodeId == edge.targetId
                        
                        drawEdge(
                            context: context,
                            from: sourceNode.position,
                            to: targetNode.position,
                            similarity: edge.similarity,
                            isHighlighted: isHighlighted
                        )
                    }
                }
                .scaleEffect(viewModel.zoomScale * autoScale)
                .offset(x: viewModel.offset.width + autoOffsetX, y: viewModel.offset.height + autoOffsetY)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            viewModel.zoomScale = value
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            viewModel.offset = value.translation
                        }
                )
                
                // ノードを描画
                ForEach(graphData.nodes) { node in
                    NodeView(
                        node: node,
                        isSelected: viewModel.selectedNodeId == node.id,
                        isConnected: isNodeConnected(node, in: graphData)
                    )
                    .position(node.position)
                    .scaleEffect(viewModel.zoomScale * autoScale)
                    .offset(x: viewModel.offset.width + autoOffsetX, y: viewModel.offset.height + autoOffsetY)
                    .onTapGesture {
                        handleNodeTap(node)
                    }
                }
                
                // 情報パネル
                if let selectedId = viewModel.selectedNodeId,
                   let selectedNode = graphData.nodes.first(where: { $0.id == selectedId }) {
                    VStack {
                        Spacer()
                        nodeInfoPanel(node: selectedNode)
                            .padding()
                    }
                }
            }
        }
    }
    
    private func drawEdge(context: GraphicsContext, from: CGPoint, to: CGPoint, similarity: Double, isHighlighted: Bool) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        
        // 線の太さ：類似度が高いほど太く（2-6pt）
        let lineWidth = CGFloat(2 + similarity * 4)
        
        // 透明度：選択時は完全に見える、通常時も見やすく
        let opacity = isHighlighted ? 1.0 : 0.6
        
        // 色：類似度に応じたグラデーション
        let color = edgeColor(for: similarity)
        
        // 影をつけて立体感を出す
        context.stroke(
            path,
            with: .color(color.opacity(opacity)),
            style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
        
        // 選択時は光るエフェクト
        if isHighlighted {
            context.stroke(
                path,
                with: .color(color.opacity(0.3)),
                style: StrokeStyle(
                    lineWidth: lineWidth + 4,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
    }
    
    private func edgeColor(for similarity: Double) -> Color {
        // より鮮やかな色で視認性向上
        if similarity > 0.85 {
            return Color(red: 0.0, green: 0.5, blue: 1.0) // 明るい青
        } else if similarity > 0.80 {
            return Color(red: 0.0, green: 0.8, blue: 0.8) // シアン
        } else {
            return Color(red: 0.6, green: 0.6, blue: 0.7) // 明るいグレー
        }
    }
    
    private func isNodeConnected(_ node: GraphNode, in graphData: GraphData) -> Bool {
        guard let selectedId = viewModel.selectedNodeId else { return false }
        
        return graphData.edges.contains { edge in
            (edge.sourceId == selectedId && edge.targetId == node.id) ||
            (edge.targetId == selectedId && edge.sourceId == node.id)
        }
    }
    
    private func handleNodeTap(_ node: GraphNode) {
        if viewModel.selectedNodeId == node.id {
            // 2回目のタップでメモ詳細を表示
            Task {
                do {
                    selectedMemo = try await MemoService.shared.fetchMemo(id: node.memoId)
                    showingMemoDetail = true
                } catch {
                    print("❌ Failed to fetch memo: \(error)")
                }
            }
        } else {
            // 1回目のタップで選択
            viewModel.selectNode(node.id)
        }
    }
    
    private func nodeInfoPanel(node: GraphNode) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(node.title)
                .font(.headline)
                .foregroundColor(.theme.text)
            
            HStack {
                Image(systemName: "link")
                    .font(.caption)
                Text("\(node.connectionCount)個の関連メモ")
                    .font(.caption)
            }
            .foregroundColor(.theme.secondaryText)
            
            if !node.tags.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(node.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.theme.accent.opacity(0.2))
                            .foregroundColor(.theme.accent)
                            .cornerRadius(8)
                    }
                }
            }
            
            Text("タップでメモを開く")
                .font(.caption2)
                .foregroundColor(.theme.secondaryText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 8)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "network.slash")
                .font(.system(size: 60))
                .foregroundColor(.theme.secondaryText)
            
            Text("グラフを表示できません")
                .font(.headline)
            
            Text("メモを作成すると、関連性が可視化されます")
                .font(.caption)
                .foregroundColor(.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct NodeView: View {
    let node: GraphNode
    let isSelected: Bool
    let isConnected: Bool
    
    private var nodeSize: CGFloat {
        let baseSize: CGFloat = 30
        let sizeBonus = CGFloat(min(node.connectionCount, 10)) * 3
        return baseSize + sizeBonus
    }
    
    private var nodeColor: Color {
        if isSelected {
            return .theme.accent
        } else if isConnected {
            return .blue
        } else {
            return .gray
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .shadow(radius: isSelected ? 8 : 2)
            
            if isSelected || node.connectionCount > 5 {
                Text(node.title)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: nodeSize * 2)
                    .offset(y: nodeSize + 10)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    KnowledgeGraphView()
}
