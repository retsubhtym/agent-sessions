import SwiftUI

// A simple wrapping layout that flows subviews horizontally and wraps to the next line.
struct Flow: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let layout = layoutInfo(for: subviews, proposal: proposal, widthLimit: proposal.width)
        return layout.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let widthLimit = bounds.width.isFinite ? bounds.width : nil
        let layout = layoutInfo(for: subviews, proposal: proposal, widthLimit: widthLimit)
        for (item, subview) in zip(layout.items, subviews) {
            let origin = CGPoint(x: bounds.minX + item.origin.x, y: bounds.minY + item.origin.y)
            subview.place(at: origin, proposal: ProposedViewSize(item.size))
        }
    }

    private func layoutInfo(for subviews: Subviews, proposal: ProposedViewSize, widthLimit: CGFloat?) -> (size: CGSize, items: [LayoutItem]) {
        var items: [LayoutItem] = []
        items.reserveCapacity(subviews.count)

        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var yOffset: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        let limit = widthLimit.map { max($0, 0) }
        let fittingProposal = ProposedViewSize(width: widthLimit, height: proposal.height)

        for subview in subviews {
            let size = subview.sizeThatFits(fittingProposal)
            var leadingSpacing: CGFloat = lineWidth == 0 ? 0 : spacing
            var candidateWidth = lineWidth + leadingSpacing + size.width

            if let limit, lineWidth > 0, candidateWidth > limit {
                maxLineWidth = max(maxLineWidth, lineWidth)
                yOffset += lineHeight + spacing
                lineWidth = 0
                lineHeight = 0
                leadingSpacing = 0
                candidateWidth = size.width
            }

            let origin = CGPoint(x: lineWidth + leadingSpacing, y: yOffset)
            items.append(LayoutItem(origin: origin, size: size))

            lineWidth = candidateWidth
            lineHeight = max(lineHeight, size.height)
        }

        maxLineWidth = max(maxLineWidth, lineWidth)
        let totalHeight = yOffset + lineHeight
        let totalWidth: CGFloat
        if let limit {
            totalWidth = min(maxLineWidth, limit)
        } else {
            totalWidth = maxLineWidth
        }

        return (CGSize(width: totalWidth, height: totalHeight), items)
    }

    private struct LayoutItem {
        let origin: CGPoint
        let size: CGSize
    }
}
