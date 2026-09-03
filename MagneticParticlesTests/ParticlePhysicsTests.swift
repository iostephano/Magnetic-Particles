//
//  ParticlePhysicsTests.swift
//  MagneticParticlesTests
//
//  Created by Stephano Portella on 03/09/26.
//

import Testing
import CoreGraphics
@testable import MagneticParticles

struct ParticlePhysicsTests {

    private let canvas = CGSize(width: 400, height: 800)

    // MARK: - advanceFree

    @Test("A particle away from the edges just translates by its velocity")
    func freeMotionTranslates() {
        let result = ParticlePhysics.advanceFree(
            position: CGPoint(x: 200, y: 400),
            velocity: CGVector(dx: 3, dy: -2),
            radius: 5,
            in: canvas
        )
        #expect(result.position == CGPoint(x: 203, y: 398))
        #expect(result.velocity == CGVector(dx: 3, dy: -2))
    }

    @Test("Crossing the left edge clamps the particle inside and flips dx")
    func bounceLeft() {
        let result = ParticlePhysics.advanceFree(
            position: CGPoint(x: 6, y: 400),
            velocity: CGVector(dx: -10, dy: 1),
            radius: 5,
            in: canvas
        )
        #expect(result.position.x == 5)
        #expect(result.velocity.dx == 10)
        #expect(result.velocity.dy == 1)
    }

    @Test("Crossing the right edge clamps the particle inside and flips dx")
    func bounceRight() {
        let result = ParticlePhysics.advanceFree(
            position: CGPoint(x: 396, y: 400),
            velocity: CGVector(dx: 10, dy: 0),
            radius: 5,
            in: canvas
        )
        #expect(result.position.x == 395)
        #expect(result.velocity.dx == -10)
    }

    @Test("Crossing the top and bottom edges flips dy")
    func bounceVertical() {
        let top = ParticlePhysics.advanceFree(
            position: CGPoint(x: 200, y: 4),
            velocity: CGVector(dx: 0, dy: -8),
            radius: 5,
            in: canvas
        )
        #expect(top.position.y == 5)
        #expect(top.velocity.dy == 8)

        let bottom = ParticlePhysics.advanceFree(
            position: CGPoint(x: 200, y: 797),
            velocity: CGVector(dx: 0, dy: 8),
            radius: 5,
            in: canvas
        )
        #expect(bottom.position.y == 795)
        #expect(bottom.velocity.dy == -8)
    }

    @Test("A bounce preserves the speed, only reversing the axis")
    func bouncePreservesSpeed() {
        let velocity = CGVector(dx: -7, dy: 3)
        let result = ParticlePhysics.advanceFree(
            position: CGPoint(x: 6, y: 400),
            velocity: velocity,
            radius: 5,
            in: canvas
        )
        #expect(hypot(result.velocity.dx, result.velocity.dy) == hypot(velocity.dx, velocity.dy))
    }

    // MARK: - step

    @Test("A factor of zero leaves the position unchanged")
    func stepZero() {
        let start = CGPoint(x: 10, y: 20)
        #expect(ParticlePhysics.step(from: start, toward: CGPoint(x: 100, y: 100), factor: 0) == start)
    }

    @Test("A factor of one reaches the target")
    func stepOne() {
        let target = CGPoint(x: 100, y: 100)
        #expect(ParticlePhysics.step(from: CGPoint(x: 10, y: 20), toward: target, factor: 1) == target)
    }

    @Test("A factor of one half lands on the midpoint")
    func stepHalf() {
        let result = ParticlePhysics.step(
            from: CGPoint(x: 0, y: 0),
            toward: CGPoint(x: 10, y: 40),
            factor: 0.5
        )
        #expect(result == CGPoint(x: 5, y: 20))
    }

    // MARK: - hasArrived

    @Test("A particle within the snap distance has arrived")
    func arrivedWithinSnap() {
        let target = CGPoint(x: 100, y: 100)
        #expect(ParticlePhysics.hasArrived(CGPoint(x: 100.3, y: 100), at: target))
    }

    @Test("A particle further than the snap distance has not arrived")
    func notArrivedBeyondSnap() {
        let target = CGPoint(x: 100, y: 100)
        #expect(!ParticlePhysics.hasArrived(CGPoint(x: 101, y: 100), at: target))
    }

    // MARK: - clusterOffset

    @Test("The offset points away from the touch, along the origin-to-touch line")
    func clusterOffsetDirection() {
        let offset = ParticlePhysics.clusterOffset(
            origin: CGPoint(x: 300, y: 400),
            touch: CGPoint(x: 200, y: 400),
            canvasDiagonal: hypot(canvas.width, canvas.height)
        )
        let unwrapped = try! #require(offset)
        #expect(unwrapped.dx > 0)
        #expect(unwrapped.dy == 0)
    }

    @Test("A far origin orbits near the maximum cluster radius")
    func clusterOffsetFarOrigin() {
        let diagonal = hypot(canvas.width, canvas.height)
        let offset = ParticlePhysics.clusterOffset(
            origin: CGPoint(x: canvas.width, y: canvas.height),
            touch: .zero,
            canvasDiagonal: diagonal
        )
        let magnitude = hypot(offset!.dx, offset!.dy)
        #expect(abs(magnitude - ParticlePhysics.maxClusterRadius) < 0.0001)
    }

    @Test("A near origin orbits closer to the minimum cluster radius than a far one")
    func clusterOffsetScalesWithDistance() {
        let diagonal = hypot(canvas.width, canvas.height)
        let near = ParticlePhysics.clusterOffset(
            origin: CGPoint(x: 210, y: 400),
            touch: CGPoint(x: 200, y: 400),
            canvasDiagonal: diagonal
        )!
        let far = ParticlePhysics.clusterOffset(
            origin: CGPoint(x: 390, y: 400),
            touch: CGPoint(x: 200, y: 400),
            canvasDiagonal: diagonal
        )!
        #expect(hypot(near.dx, near.dy) < hypot(far.dx, far.dy))
        #expect(hypot(near.dx, near.dy) >= ParticlePhysics.minClusterRadius)
    }

    @Test("An origin exactly on the touch has no defined direction")
    func clusterOffsetOnTouchIsNil() {
        let offset = ParticlePhysics.clusterOffset(
            origin: CGPoint(x: 200, y: 400),
            touch: CGPoint(x: 200, y: 400),
            canvasDiagonal: hypot(canvas.width, canvas.height)
        )
        #expect(offset == nil)
    }
}
