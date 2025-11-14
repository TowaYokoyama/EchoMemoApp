
import Foundation
import SwiftUI

@MainActor
class KnowledgeGraphViewModel: ObservableObject {
    @Published var graphData: GraphData?
    @Published var selectedNodeId: String?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var zoomScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var filterTag: String?
    @Published var useDemoData = true  // デモモード（開発用）
    
    private var allMemos: [Memo] = []
    private let layoutIterations = 50
    
    /// グラフデータを読み込む
    func loadGraph() async {
        isLoading = true
        error = nil
        
        // デモモードの場合はダミーデータを使用
        if useDemoData {
            print("🎨 [GRAPH] Loading demo data...")
            graphData = GraphData.createDemoGraph()
            isLoading = false
            return
        }
        
        do {
            // メモを取得
            allMemos = try await MemoService.shared.fetchMemos(limit: 100)
            
            // グラフデータを構築
            var graph = GraphData.build(from: allMemos)
            
            // レイアウトを適用
            graph = applyForceDirectedLayout(to: graph)
            
            graphData = graph
            print("✅ [GRAPH] Loaded graph with \(graph.nodes.count) nodes and \(graph.edges.count) edges")
        } catch {
            print("❌ [GRAPH] Failed to load graph: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    /// デモモードを切り替え
    func toggleDemoMode() {
        useDemoData.toggle()
        Task {
            await loadGraph()
        }
    }
    
    /// ノードを選択
    func selectNode(_ nodeId: String?) {
        selectedNodeId = nodeId
    }
    
    /// タグでフィルタリング
    func filterByTag(_ tag: String?) {
        filterTag = tag
        
        if let tag = tag {
            let filteredMemos = allMemos.filter { $0.tags.contains(tag) }
            var graph = GraphData.build(from: filteredMemos)
            graph = applyForceDirectedLayout(to: graph)
            graphData = graph
        } else {
            var graph = GraphData.build(from: allMemos)
            graph = applyForceDirectedLayout(to: graph)
            graphData = graph
        }
    }
    
    /// Force-Directed Layoutアルゴリズムを適用
    private func applyForceDirectedLayout(to graph: GraphData) -> GraphData {
        guard !graph.nodes.isEmpty else { return graph }
        
        var nodes = graph.nodes
        let edges = graph.edges
        
        // 初期位置をランダムに配置
        let centerX: CGFloat = 200
        let centerY: CGFloat = 200
        let radius: CGFloat = 150
        
        for i in 0..<nodes.count {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(nodes.count))
            nodes[i].position = CGPoint(
                x: centerX + radius * cos(angle),
                y: centerY + radius * sin(angle)
            )
        }
        
        // 力学シミュレーション
        let repulsionStrength: CGFloat = 1000
        let attractionStrength: CGFloat = 0.01
        let damping: CGFloat = 0.5
        
        for _ in 0..<layoutIterations {
            var forces = Array(repeating: CGPoint.zero, count: nodes.count)
            
            // 反発力（全ノード間）
            for i in 0..<nodes.count {
                for j in (i+1)..<nodes.count {
                    let dx = nodes[j].position.x - nodes[i].position.x
                    let dy = nodes[j].position.y - nodes[i].position.y
                    let distance = max(sqrt(dx*dx + dy*dy), 1)
                    let force = repulsionStrength / (distance * distance)
                    
                    let fx = (dx / distance) * force
                    let fy = (dy / distance) * force
                    
                    forces[i].x -= fx
                    forces[i].y -= fy
                    forces[j].x += fx
                    forces[j].y += fy
                }
            }
            
            // 引力（エッジで接続されたノード間）
            for edge in edges {
                guard let sourceIndex = nodes.firstIndex(where: { $0.id == edge.sourceId }),
                      let targetIndex = nodes.firstIndex(where: { $0.id == edge.targetId }) else {
                    continue
                }
                
                let dx = nodes[targetIndex].position.x - nodes[sourceIndex].position.x
                let dy = nodes[targetIndex].position.y - nodes[sourceIndex].position.y
                let distance = sqrt(dx*dx + dy*dy)
                let force = attractionStrength * distance
                
                let fx = (dx / distance) * force
                let fy = (dy / distance) * force
                
                forces[sourceIndex].x += fx
                forces[sourceIndex].y += fy
                forces[targetIndex].x -= fx
                forces[targetIndex].y -= fy
            }
            
            // 力を適用
            for i in 0..<nodes.count {
                nodes[i].position.x += forces[i].x * damping
                nodes[i].position.y += forces[i].y * damping
            }
        }
        
        return GraphData(nodes: nodes, edges: edges)
    }
    
    /// ズームをリセット
    func resetZoom() {
        zoomScale = 1.0
        offset = .zero
    }
}
