//
//  TimelineDragGesture.swift
//  BeautyCRM
//
//  Дотик і перетягування запису на шкалі. Зроблено через UIKit: жест SwiftUI
//  усередині ScrollView або блокує прокрутку, або поводиться по-різному на різних iOS.
//

import SwiftUI
import UIKit


struct TimelineDragGesture: UIViewRepresentable {

    let canDrag: Bool
    let onTap: () -> Void
    // Повертає, на скільки шкала виросла зверху: прокрутку треба зсунути на стільки ж
    let onBegan: () -> CGFloat
    let onChanged: (CGFloat) -> Void
    // Повертає, на скільки шкала зменшилась зверху
    let onEnded: (_ cancelled: Bool) -> CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {

        let view = UIView()
        view.backgroundColor = .clear

        let long = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        long.minimumPressDuration = 0.35
        view.addGestureRecognizer(long)
        context.coordinator.longPress = long

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap)
        )
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.longPress?.isEnabled = canDrag
    }


    final class Coordinator: NSObject {

        var parent: TimelineDragGesture
        weak var longPress: UILongPressGestureRecognizer?

        private weak var scrollView: UIScrollView?
        private var startY: CGFloat = 0
        private var startOnScreen: CGFloat = 0
        private var displayLink: CADisplayLink?

        private let edgeZone: CGFloat = 70
        private let scrollStep: CGFloat = 6
        private let edgeIntent: CGFloat = 10

        init(_ parent: TimelineDragGesture) {
            self.parent = parent
        }

        @objc func handleTap() {
            parent.onTap()
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {

            switch gesture.state {

            case .began:
                begin(gesture)

            case .changed:
                report()

            case .ended:
                finish(cancelled: false)

            case .cancelled, .failed:
                finish(cancelled: true)

            default:
                break
            }
        }

        private func begin(_ gesture: UILongPressGestureRecognizer) {

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            scrollView = enclosingScrollView(of: gesture.view)
            scrollView?.isScrollEnabled = false

            let grown = parent.onBegan()
            shiftScroll(by: grown)

            // Прокрутку вже зсунуто, тож положення пальця вмісту вже враховує ріст шкали
            startY = location()
            startOnScreen = location() - (scrollView?.contentOffset.y ?? 0)

            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func finish(cancelled: Bool) {

            displayLink?.invalidate()
            displayLink = nil

            let shrunk = parent.onEnded(cancelled)

            shiftScroll(by: -shrunk)
            scrollView?.isScrollEnabled = true
            scrollView = nil
        }

        private func report() {
            parent.onChanged(location() - startY)
        }

        // Положення пальця у вмісті прокрутки: враховує автопрокрутку
        private func location() -> CGFloat {
            longPress?.location(in: scrollView ?? longPress?.view).y ?? 0
        }

        // Палець біля краю екрана — прокручуємо шкалу самі
        @objc private func tick() {

            guard let scrollView else {
                return
            }

            let insets = scrollView.adjustedContentInset
            let fingerOnScreen = location() - scrollView.contentOffset.y
            let top = insets.top + edgeZone
            let bottom = scrollView.bounds.height - insets.bottom - edgeZone

            let minOffset = -insets.top
            let maxOffset = max(
                scrollView.contentSize.height + insets.bottom - scrollView.bounds.height,
                minOffset
            )

            var offset = scrollView.contentOffset.y

            // Лише коли палець рухається до краю: запис, який уже стоїть
            // біля краю, не має поїхати сам одразу після затискання
            let movedUp = fingerOnScreen < startOnScreen - edgeIntent
            let movedDown = fingerOnScreen > startOnScreen + edgeIntent

            if fingerOnScreen < top && movedUp {
                offset = max(offset - scrollStep, minOffset)
            } else if fingerOnScreen > bottom && movedDown {
                offset = min(offset + scrollStep, maxOffset)
            } else {
                return
            }

            guard offset != scrollView.contentOffset.y else {
                return
            }

            scrollView.contentOffset.y = offset
            report()
        }

        private func shiftScroll(by delta: CGFloat) {

            guard let scrollView, delta != 0 else {
                return
            }

            scrollView.contentOffset.y = max(
                scrollView.contentOffset.y + delta,
                -scrollView.adjustedContentInset.top
            )
        }

        private func enclosingScrollView(of view: UIView?) -> UIScrollView? {

            var current = view?.superview

            while let candidate = current {
                if let scrollView = candidate as? UIScrollView {
                    return scrollView
                }
                current = candidate.superview
            }

            return nil
        }
    }
}
