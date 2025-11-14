
import Foundation
import CoreGraphics

/// ナレッジグラフ全体のデータ
struct GraphData {
    let nodes: [GraphNode]
    let edges: [GraphEdge]
}

/// グラフのノード（メモを表す）
struct GraphNode: Identifiable, Equatable {
    let id: String
    let memoId: String
    let title: String
    let tags: [String]
    let connectionCount: Int
    var position: CGPoint
    let createdAt: Date
    
    static func == (lhs: GraphNode, rhs: GraphNode) -> Bool {
        lhs.id == rhs.id
    }
}

/// グラフのエッジ（メモ間の関連性を表す）
struct GraphEdge: Identifiable, Equatable {
    let id: String
    let sourceId: String
    let targetId: String
    let similarity: Double
    
    static func == (lhs: GraphEdge, rhs: GraphEdge) -> Bool {
        lhs.id == rhs.id
    }
}

/// グラフ構築のヘルパー
extension GraphData {
    /// ダミーデータでグラフを作成（デモ用）
    static func createDemoGraph() -> GraphData {
        // 画面中央を基準に配置（iPhone画面サイズを考慮）
        let centerX: CGFloat = 180
        let centerY: CGFloat = 300
        
        // ダミーノードを作成（画面内に収まるように配置）
        let node1 = GraphNode(
            id: "1",
            memoId: "1",
            title: "AI技術",
            tags: ["技術", "AI"],
            connectionCount: 3,
            position: CGPoint(x: centerX, y: centerY - 120),
            createdAt: Date()
        )
        
        let node2 = GraphNode(
            id: "2",
            memoId: "2",
            title: "機械学習",
            tags: ["技術", "AI", "学習"],
            connectionCount: 4,
            position: CGPoint(x: centerX + 100, y: centerY - 80),
            createdAt: Date()
        )
        
        let node3 = GraphNode(
            id: "3",
            memoId: "3",
            title: "ディープラーニング",
            tags: ["AI", "学習"],
            connectionCount: 2,
            position: CGPoint(x: centerX + 50, y: centerY),
            createdAt: Date()
        )
        
        let node4 = GraphNode(
            id: "4",
            memoId: "4",
            title: "自然言語処理",
            tags: ["AI", "言語"],
            connectionCount: 3,
            position: CGPoint(x: centerX - 80, y: centerY + 80),
            createdAt: Date()
        )
        
        let node5 = GraphNode(
            id: "5",
            memoId: "5",
            title: "画像認識",
            tags: ["AI", "画像"],
            connectionCount: 2,
            position: CGPoint(x: centerX + 100, y: centerY + 100),
            createdAt: Date()
        )
        
        let node6 = GraphNode(
            id: "6",
            memoId: "6",
            title: "データ分析",
            tags: ["データ", "分析"],
            connectionCount: 2,
            position: CGPoint(x: centerX, y: centerY + 150),
            createdAt: Date()
        )
        
        // ダミーエッジを作成（繋がり線）
        let edge1 = GraphEdge(
            id: "1-2",
            sourceId: "1",
            targetId: "2",
            similarity: 0.92  // 強い関連性
        )
        
        let edge2 = GraphEdge(
            id: "1-3",
            sourceId: "1",
            targetId: "3",
            similarity: 0.88  // 強い関連性
        )
        
        let edge3 = GraphEdge(
            id: "2-3",
            sourceId: "2",
            targetId: "3",
            similarity: 0.95  // 非常に強い関連性
        )
        
        let edge4 = GraphEdge(
            id: "2-4",
            sourceId: "2",
            targetId: "4",
            similarity: 0.85  // 中程度の関連性
        )
        
        let edge5 = GraphEdge(
            id: "2-5",
            sourceId: "2",
            targetId: "5",
            similarity: 0.87  // 強い関連性
        )
        
        let edge6 = GraphEdge(
            id: "3-4",
            sourceId: "3",
            targetId: "4",
            similarity: 0.82  // 中程度の関連性
        )
        
        let edge7 = GraphEdge(
            id: "3-5",
            sourceId: "3",
            targetId: "5",
            similarity: 0.84  // 中程度の関連性
        )
        
        let edge8 = GraphEdge(
            id: "4-6",
            sourceId: "4",
            targetId: "6",
            similarity: 0.78  // 弱い関連性
        )
        
        let edge9 = GraphEdge(
            id: "5-6",
            sourceId: "5",
            targetId: "6",
            similarity: 0.80  // 中程度の関連性
        )
        
        let nodes = [node1, node2, node3, node4, node5, node6]
        let edges = [edge1, edge2, edge3, edge4, edge5, edge6, edge7, edge8, edge9]
        
        print("🎨 [DEMO] Created demo graph with \(nodes.count) nodes and \(edges.count) edges")
        print("  📊 Connections:")
        print("    AI技術 ←→ 機械学習 (0.92)")
        print("    AI技術 ←→ ディープラーニング (0.88)")
        print("    機械学習 ←→ ディープラーニング (0.95)")
        print("    機械学習 ←→ 自然言語処理 (0.85)")
        print("    機械学習 ←→ 画像認識 (0.87)")
        print("    ディープラーニング ←→ 自然言語処理 (0.82)")
        print("    ディープラーニング ←→ 画像認識 (0.84)")
        print("    自然言語処理 ←→ データ分析 (0.78)")
        print("    画像認識 ←→ データ分析 (0.80)")
        
        return GraphData(nodes: nodes, edges: edges)
    }
    
    /// メモリストからグラフデータを構築
    static func build(from memos: [Memo]) -> GraphData {
        var nodes: [GraphNode] = []
        var edges: [GraphEdge] = []
        var edgeSet = Set<String>()
        
        print("🔨 [GRAPH] Building graph from \(memos.count) memos")
        
        // ノードを作成
        for memo in memos {
            let connectionCount = memo.relatedMemoIds?.count ?? 0
            let node = GraphNode(
                id: memo.id,
                memoId: memo.id,
                title: memo.title,
                tags: memo.tags,
                connectionCount: connectionCount,
                position: .zero, // 初期位置はゼロ、後でレイアウトアルゴリズムで配置
                createdAt: memo.createdAt
            )
            nodes.append(node)
            
            if let relatedIds = memo.relatedMemoIds, !relatedIds.isEmpty {
                print("  📎 Memo '\(memo.title)' has \(relatedIds.count) connections: \(relatedIds)")
            }
        }
        
        print("✅ [GRAPH] Created \(nodes.count) nodes")
        
        // エッジを作成（重複を避ける）
        for memo in memos {
            guard let relatedIds = memo.relatedMemoIds else { continue }
            
            for relatedId in relatedIds {
                // 双方向リンクの重複を避けるため、IDの小さい方を常にsourceにする
                let sourceId = min(memo.id, relatedId)
                let targetId = max(memo.id, relatedId)
                let edgeId = "\(sourceId)-\(targetId)"
                
                // 既に追加済みならスキップ
                if edgeSet.contains(edgeId) { continue }
                
                // 両方のノードが存在する場合のみエッジを追加
                if nodes.contains(where: { $0.id == sourceId }) &&
                   nodes.contains(where: { $0.id == targetId }) {
                    let edge = GraphEdge(
                        id: edgeId,
                        sourceId: sourceId,
                        targetId: targetId,
                        similarity: 0.8 // デフォルト値、実際はバックエンドから取得
                    )
                    edges.append(edge)
                    edgeSet.insert(edgeId)
                    print("  🔗 Created edge: \(sourceId) <-> \(targetId)")
                } else {
                    print("  ⚠️ Skipped edge \(sourceId) <-> \(targetId) (node not found)")
                }
            }
        }
        
        print("✅ [GRAPH] Created \(edges.count) edges")
        
        return GraphData(nodes: nodes, edges: edges)
    }
}


