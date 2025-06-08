//
//  MagneticParticlesView.swift
//  Magnetic Particles
//
//  Created by Stephano Portella on 04/06/25.
//

import UIKit

private struct Particle {
    let layer: CAShapeLayer
    let originalPosition: CGPoint
    var velocity: CGVector
    var clusterOffset: CGVector = .zero
}

class MagneticParticlesView: UIView {
    private let numberOfParticles = 100
    private let minRadius: CGFloat = 3
    private let maxRadius: CGFloat = 10
    private let colors: [UIColor] = [.white, .systemYellow, .systemBlue]
    private var particles: [Particle] = []
    private var displayLink: CADisplayLink?
    private var isTouching = false
    private var touchPoint: CGPoint?
    private var isReturning = false
    private var didSetupParticles = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
    }

    deinit {
        displayLink?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didSetupParticles {
            didSetupParticles = true
            setupParticles()
            startDisplayLink()
        }
    }

    private func setupParticles() {
        particles.forEach { $0.layer.removeFromSuperlayer() }
        particles = []
        let width = bounds.width
        let height = bounds.height

        for i in 0..<numberOfParticles {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let color = colors[i % colors.count]
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(
                ovalIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
            ).cgPath
            layer.fillColor = color.cgColor
            layer.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)

            let x = CGFloat.random(in: radius...(width - radius))
            let y = CGFloat.random(in: radius...(height - radius))
            let position = CGPoint(x: x, y: y)
            layer.position = position

            let dx = CGFloat.random(in: -1.0...1.0)
            let dy = CGFloat.random(in: -1.0...1.0)
            let velocity = CGVector(dx: dx, dy: dy)

            var particle = Particle(
                layer: layer,
                originalPosition: position,
                velocity: velocity
            )
            particle.clusterOffset = .zero

            particles.append(particle)
            self.layer.addSublayer(layer)
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateParticles))
        displayLink?.add(to: .main, forMode: .default)
    }

    @objc private func updateParticles() {
        guard !particles.isEmpty else { return }

        if isTouching, let touch = touchPoint {
            for i in 0..<particles.count {
                var particle = particles[i]
                let pos = particle.layer.position
                let targetX = touch.x + particle.clusterOffset.dx
                let targetY = touch.y + particle.clusterOffset.dy
                let dx = targetX - pos.x
                let dy = targetY - pos.y
                let attraction: CGFloat = 0.12
                let newX = pos.x + dx * attraction
                let newY = pos.y + dy * attraction
                particle.layer.position = CGPoint(x: newX, y: newY)
                particles[i] = particle
            }

        } else if isReturning {
            var allAtOrigin = true
            for i in 0..<particles.count {
                var particle = particles[i]
                let pos = particle.layer.position
                let orig = particle.originalPosition
                let dx = orig.x - pos.x
                let dy = orig.y - pos.y
                if hypot(dx, dy) < 0.5 {
                    particle.layer.position = orig
                } else {
                    allAtOrigin = false
                    let returnSpeed: CGFloat = 0.08
                    let newX = pos.x + dx * returnSpeed
                    let newY = pos.y + dy * returnSpeed
                    particle.layer.position = CGPoint(x: newX, y: newY)
                }
                particles[i] = particle
            }
            if allAtOrigin {
                isReturning = false
            }

        } else {
            let width = bounds.width
            let height = bounds.height

            for i in 0..<particles.count {
                var particle = particles[i]
                var pos = particle.layer.position
                var vel = particle.velocity
                let radius = particle.layer.bounds.width / 2

                var newX = pos.x + vel.dx
                var newY = pos.y + vel.dy

                if newX - radius < 0 {
                    newX = radius
                    vel.dx *= -1
                } else if newX + radius > width {
                    newX = width - radius
                    vel.dx *= -1
                }
                if newY - radius < 0 {
                    newY = radius
                    vel.dy *= -1
                } else if newY + radius > height {
                    newY = height - radius
                    vel.dy *= -1
                }

                pos = CGPoint(x: newX, y: newY)
                particle.layer.position = pos
                particle.velocity = vel
                particles[i] = particle
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isTouching = true
        isReturning = false
        let pt = touch.location(in: self)
        touchPoint = pt

        let maxClusterRadius: CGFloat = 40
        let width = bounds.width
        let height = bounds.height
        let maxDiagonal = hypot(width, height)

        for i in 0..<particles.count {
            var particle = particles[i]
            let orig = particle.originalPosition
            let dx = orig.x - pt.x
            let dy = orig.y - pt.y
            let dist = hypot(dx, dy)
            if dist > 0 {
                let nx = dx / dist
                let ny = dy / dist
                let factorDistance = min(dist / maxDiagonal, 1)
                let minClusterRadius: CGFloat = 10
                let r = minClusterRadius + (maxClusterRadius - minClusterRadius) * factorDistance
                particle.clusterOffset = CGVector(dx: nx * r, dy: ny * r)
            } else {
                let angle = CGFloat.random(in: 0..<(2 * .pi))
                let r = CGFloat.random(in: 10...maxClusterRadius)
                particle.clusterOffset = CGVector(dx: cos(angle) * r, dy: sin(angle) * r)
            }
            particles[i] = particle
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchPoint = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        isReturning = true
        touchPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        isReturning = true
        touchPoint = nil
    }
}
