//
//  ParticlePhysics.swift
//  MagneticParticles
//
//  Created by Stephano Portella on 03/09/26.
//

import Foundation

/// Operaciones puras de la simulación, sin UIKit ni Core Animation, para poder
/// probarlas de forma aislada. `MagneticParticlesView` las aplica sobre las capas
/// reales cada frame.
enum ParticlePhysics {

    /// Fracción del camino restante que una partícula recorre por frame al ser
    /// atraída hacia el toque.
    static let attraction: CGFloat = 0.12

    /// Fracción del camino restante por frame al regresar a su posición original.
    static let returnSpeed: CGFloat = 0.08

    /// Radio mínimo y máximo del cúmulo alrededor del punto de toque.
    static let minClusterRadius: CGFloat = 10
    static let maxClusterRadius: CGFloat = 40

    /// Distancia por debajo de la cual una partícula se fija exactamente en su
    /// destino, para que la interpolación no oscile indefinidamente.
    static let snapDistance: CGFloat = 0.5

    /// Un paso de movimiento libre: avanza `position` según `velocity` y rebota de
    /// forma elástica contra los bordes de un lienzo de tamaño `size`, dejando la
    /// partícula (de radio `radius`) siempre dentro.
    static func advanceFree(
        position: CGPoint,
        velocity: CGVector,
        radius: CGFloat,
        in size: CGSize
    ) -> (position: CGPoint, velocity: CGVector) {
        var x = position.x + velocity.dx
        var y = position.y + velocity.dy
        var velocity = velocity

        if x - radius < 0 {
            x = radius
            velocity.dx *= -1
        } else if x + radius > size.width {
            x = size.width - radius
            velocity.dx *= -1
        }

        if y - radius < 0 {
            y = radius
            velocity.dy *= -1
        } else if y + radius > size.height {
            y = size.height - radius
            velocity.dy *= -1
        }

        return (CGPoint(x: x, y: y), velocity)
    }

    /// Interpola `position` una fracción `factor` (0...1) hacia `target`. Se usa
    /// tanto para la atracción magnética como para el regreso al origen.
    static func step(from position: CGPoint, toward target: CGPoint, factor: CGFloat) -> CGPoint {
        CGPoint(
            x: position.x + (target.x - position.x) * factor,
            y: position.y + (target.y - position.y) * factor
        )
    }

    /// True si `position` está lo bastante cerca de `target` como para fijarla.
    static func hasArrived(_ position: CGPoint, at target: CGPoint) -> Bool {
        hypot(target.x - position.x, target.y - position.y) < snapDistance
    }

    /// Offset de una partícula respecto al punto de toque al formar el cúmulo:
    /// cuanto más lejos está su origen del toque, más lejos orbita del centro. El
    /// radio interpola entre `minClusterRadius` y `maxClusterRadius` según la
    /// distancia relativa a `canvasDiagonal`. Devuelve `nil` cuando el origen
    /// coincide exactamente con el toque; en ese caso el llamador coloca un offset
    /// aleatorio, porque no hay una dirección "hacia afuera" definida.
    static func clusterOffset(
        origin: CGPoint,
        touch: CGPoint,
        canvasDiagonal: CGFloat
    ) -> CGVector? {
        let dx = origin.x - touch.x
        let dy = origin.y - touch.y
        let distance = hypot(dx, dy)
        guard distance > 0 else { return nil }

        let reach = min(distance / canvasDiagonal, 1)
        let radius = minClusterRadius + (maxClusterRadius - minClusterRadius) * reach
        return CGVector(dx: dx / distance * radius, dy: dy / distance * radius)
    }
}
