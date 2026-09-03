//
//  MagneticParticlesView.swift
//  MagneticParticles
//
//  Created by Stephano Portella on 04/06/25.
//

import UIKit

private struct Particle {
    let layer: CAShapeLayer
    var originalPosition: CGPoint
    var velocity: CGVector
    var clusterOffset: CGVector = .zero
}

/// Vista que dibuja un centenar de partículas con `CAShapeLayer`, las mueve por
/// frame con un `CADisplayLink` y reacciona al toque: mientras el dedo está sobre
/// la vista las agrupa en un cúmulo a su alrededor; al soltar, cada una vuelve a
/// su posición original. La física está en `ParticlePhysics`; aquí solo se
/// orquesta sobre las capas y el estado de la interacción.
final class MagneticParticlesView: UIView {

    private let numberOfParticles = 100
    private let minRadius: CGFloat = 3
    private let maxRadius: CGFloat = 10
    private let colors: [UIColor] = [.white, .systemYellow, .systemBlue]

    private var particles: [Particle] = []
    private var displayLink: CADisplayLink?
    private var touchPoint: CGPoint?
    private var isTouching = false
    private var isReturning = false

    /// Tamaño con el que se generaron las partículas actuales. Sirve para no
    /// reconstruirlas en cada ciclo de layout y para detectar un cambio real de
    /// tamaño (p. ej. al añadir la vista a otra jerarquía).
    private var builtSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // El `CADisplayLink` retiene su target: pausarlo al salir de la ventana
        // rompe ese ciclo y deja que la vista se libere.
        if window == nil {
            stopDisplayLink()
        } else {
            startDisplayLink()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = bounds.size
        // En algunos ciclos de layout la vista aún mide casi nada; generar
        // posiciones aleatorias ahí produciría un rango invertido y un crash.
        guard size.width > maxRadius * 2, size.height > maxRadius * 2 else { return }
        guard size != builtSize else { return }
        setupParticles(in: size)
    }

    private func setupParticles(in size: CGSize) {
        particles.forEach { $0.layer.removeFromSuperlayer() }
        particles.removeAll(keepingCapacity: true)
        isTouching = false
        isReturning = false
        touchPoint = nil
        builtSize = size

        for i in 0..<numberOfParticles {
            let radius = CGFloat.random(in: minRadius...maxRadius)
            let shape = CAShapeLayer()
            shape.path = UIBezierPath(
                ovalIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2)
            ).cgPath
            shape.fillColor = colors[i % colors.count].cgColor
            shape.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)

            let position = CGPoint(
                x: CGFloat.random(in: radius...(size.width - radius)),
                y: CGFloat.random(in: radius...(size.height - radius))
            )
            shape.position = position

            particles.append(
                Particle(
                    layer: shape,
                    originalPosition: position,
                    velocity: CGVector(
                        dx: CGFloat.random(in: -1...1),
                        dy: CGFloat.random(in: -1...1)
                    )
                )
            )
            layer.addSublayer(shape)
        }
    }

    private func startDisplayLink() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(updateParticles))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateParticles() {
        guard !particles.isEmpty else { return }

        if isTouching, let touch = touchPoint {
            for i in particles.indices {
                let target = CGPoint(
                    x: touch.x + particles[i].clusterOffset.dx,
                    y: touch.y + particles[i].clusterOffset.dy
                )
                particles[i].layer.position = ParticlePhysics.step(
                    from: particles[i].layer.position,
                    toward: target,
                    factor: ParticlePhysics.attraction
                )
            }
        } else if isReturning {
            var allAtOrigin = true
            for i in particles.indices {
                let origin = particles[i].originalPosition
                if ParticlePhysics.hasArrived(particles[i].layer.position, at: origin) {
                    particles[i].layer.position = origin
                } else {
                    allAtOrigin = false
                    particles[i].layer.position = ParticlePhysics.step(
                        from: particles[i].layer.position,
                        toward: origin,
                        factor: ParticlePhysics.returnSpeed
                    )
                }
            }
            if allAtOrigin { isReturning = false }
        } else {
            let size = bounds.size
            for i in particles.indices {
                let result = ParticlePhysics.advanceFree(
                    position: particles[i].layer.position,
                    velocity: particles[i].velocity,
                    radius: particles[i].layer.bounds.width / 2,
                    in: size
                )
                particles[i].layer.position = result.position
                particles[i].velocity = result.velocity
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        isTouching = true
        isReturning = false
        let point = touch.location(in: self)
        touchPoint = point

        let diagonal = hypot(bounds.width, bounds.height)
        for i in particles.indices {
            if let offset = ParticlePhysics.clusterOffset(
                origin: particles[i].originalPosition,
                touch: point,
                canvasDiagonal: diagonal
            ) {
                particles[i].clusterOffset = offset
            } else {
                let angle = CGFloat.random(in: 0..<(2 * .pi))
                let radius = CGFloat.random(
                    in: ParticlePhysics.minClusterRadius...ParticlePhysics.maxClusterRadius
                )
                particles[i].clusterOffset = CGVector(dx: cos(angle) * radius, dy: sin(angle) * radius)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchPoint = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endTouch()
    }

    private func endTouch() {
        isTouching = false
        isReturning = true
        touchPoint = nil
    }
}
