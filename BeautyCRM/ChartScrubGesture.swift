//
//  ChartScrubGesture.swift
//  BeautyCRM
//
//  Вибір стовпчика графіка пальцем: тап — вибрати/зняти, провести вбік — вибір «їде» за пальцем
//  з легкою віддачею. Через UIKit, як і TimelineDragGesture: жест SwiftUI всередині ScrollView
//  перехоплює прокрутка. Горизонтальний рух — наш, вертикальний — гортання сторінки, як і раніше.
//

import SwiftUI
import UIKit


struct ChartScrubGesture: UIViewRepresentable {

    // Тап
    let onTap: (CGPoint) -> Void
    // Палець веде вбік — вибрати стовпчик під ним; повертає ключ стовпчика (віддача при зміні)
    let onScrub: (CGPoint) -> String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {

        let view = UIView()
        view.backgroundColor = .clear

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.parent = self
    }


    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var parent: ChartScrubGesture
        private var lastKey: String?
        private let feedback = UISelectionFeedbackGenerator()

        init(_ parent: ChartScrubGesture) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            parent.onTap(gesture.location(in: gesture.view))
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                feedback.prepare()
                lastKey = nil
                fallthrough
            case .changed:
                let key = parent.onScrub(gesture.location(in: gesture.view))
                if let key, key != lastKey {
                    feedback.selectionChanged()
                    lastKey = key
                }
            default:
                lastKey = nil
            }
        }

        // Прокрутка сторінки чекає, поки наш жест вирішить: вбік — наш, вгору-вниз — гортання
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer.view is UIScrollView
        }

        // Починаємо лише тоді, коли палець іде вбік; вгору-вниз — це гортання сторінки
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            // Зсув надійніший за швидкість: на початку руху швидкість буває нульовою
            let move = pan.translation(in: pan.view)
            let velocity = pan.velocity(in: pan.view)
            let dx = abs(move.x) + abs(velocity.x) * 0.01
            let dy = abs(move.y) + abs(velocity.y) * 0.01
            return dx > dy
        }
    }
}

