# MagneticParticles — Partículas que reaccionan al toque con un efecto magnético

MagneticParticles es una app de iOS que dibuja un centenar de partículas de colores
rebotando sobre un fondo negro. Mientras mantienes el dedo sobre la pantalla, las
partículas se agrupan en un cúmulo alrededor del punto de toque, orbitándolo a
distintas distancias según de dónde venían; al soltar, cada una regresa suavemente a
su posición original y retoma su movimiento libre. Existe como proyecto de portafolio
para mostrar una animación interactiva dirigida por `CADisplayLink`, con la física
separada en un tipo puro y verificable.

<img width="2240" height="1260" alt="MagneticParticles" src="https://github.com/user-attachments/assets/494a67a7-5f32-4a09-8b32-247046c1c7d5" />

---

## Tecnologías usadas

- Swift 6 (con verificación estricta de concurrencia activada)
- UIKit, construido por código (sin Storyboards)
- Core Animation (`CAShapeLayer`, `CADisplayLink`)
- Core Graphics y `hypot` / trigonometría para la física de vectores
- Swift Testing para las pruebas
- Integración continua con GitHub Actions (compila y corre los tests en cada push/PR)
- Cero dependencias externas

---

## Cómo está organizado el proyecto

```
MagneticParticles/
├── AppDelegate.swift / SceneDelegate.swift   # Arranque; SceneDelegate crea el ViewController
├── Controllers/
│   └── ViewController.swift                  # Pantalla única: aloja la vista de partículas
├── Views/
│   └── MagneticParticlesView.swift           # Capas, CADisplayLink y estado de la interacción
└── Particles/
    └── ParticlePhysics.swift                 # Física pura: rebote, interpolación, cúmulo
```

`ParticlePhysics` no importa UIKit ni Core Animation: son funciones puras sobre
`CGPoint` / `CGVector`. `MagneticParticlesView` se limita a aplicar esos resultados
sobre las `CAShapeLayer` reales cada frame y a llevar el estado del toque.

---

## Cómo funciona / flujo principal

1. `SceneDelegate` crea el `ViewController`, que añade una `MagneticParticlesView` a
   pantalla completa sobre fondo negro.
2. En el primer ciclo de layout con un tamaño utilizable, la vista genera 100
   partículas en posiciones y velocidades aleatorias, cada una como una `CAShapeLayer`
   circular, y arranca un `CADisplayLink`.
3. En estado libre, cada frame `ParticlePhysics.advanceFree` avanza la partícula según
   su velocidad y la rebota de forma elástica contra los bordes.
4. Al tocar, `ParticlePhysics.clusterOffset` calcula para cada partícula un offset
   respecto al punto de toque: cuanto más lejos estaba su origen, más lejos orbita del
   centro del cúmulo. Cada frame la partícula interpola una fracción del camino hacia
   ese objetivo (`step`).
5. Al mover el dedo, el objetivo del cúmulo sigue al toque.
6. Al soltar (o al cancelarse el toque), la vista pasa a estado de regreso: cada
   partícula interpola hacia su posición original y se fija cuando entra en la
   distancia de snap; cuando todas llegaron, se vuelve al movimiento libre.

---

## Funcionalidades / qué demuestra

- Animación por frame con `CADisplayLink` en modo `.common`, con el ciclo de vida
  atado a la ventana para no dejar el timer corriendo ni filtrar la vista.
- Rebote elástico contra los bordes con conservación de la rapidez.
- Atracción "magnética" hacia el toque con un offset por partícula, de modo que el
  cúmulo conserva algo de la disposición original en lugar de colapsar a un punto.
- Regreso interpolado a la posición de partida con fijado por umbral.
- Física aislada en un tipo puro, cubierta por pruebas unitarias sin simulador gráfico.
- Interfaz por código, sin Storyboards, pensada para fondo negro.

---

## Pruebas

`MagneticParticlesTests` (Swift Testing) cubre `ParticlePhysics`:

- **`advanceFree`**: una partícula lejos de los bordes solo se traslada por su
  velocidad; al cruzar cada borde (izquierdo, derecho, superior, inferior) queda
  fijada dentro del lienzo y se invierte el eje correspondiente; el rebote conserva la
  rapidez.
- **`step`**: factor 0 no mueve; factor 1 llega al destino; factor 0.5 cae en el punto
  medio.
- **`hasArrived`**: dentro de la distancia de snap devuelve verdadero; más lejos,
  falso.
- **`clusterOffset`**: el offset apunta hacia afuera del toque siguiendo la recta
  origen-toque; un origen lejano orbita cerca del radio máximo; uno cercano orbita más
  cerca del mínimo; un origen que coincide con el toque devuelve `nil` (sin dirección
  definida).

Correr los tests:

```bash
xcodebuild test \
  -project MagneticParticles.xcodeproj \
  -scheme MagneticParticles \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Cómo correr el proyecto

1. Clona el repo:
   ```bash
   git clone https://github.com/iostephano/Magnetic-Particles.git
   ```
2. Abre `MagneticParticles.xcodeproj` con **Xcode 26** (ver `.xcode-version`).
3. El objetivo mínimo es **iOS 26**. Elige un simulador de iPhone o un dispositivo y
   ejecuta (Cmd-R).
4. Mantén el dedo sobre la pantalla para agrupar las partículas y suéltalo para que
   regresen.

---

## Cosas pendientes o limitadas (a propósito)

- **Toda la simulación corre en CPU** sobre `CAShapeLayer`. Para 100 partículas va
  sobrada; no se usa Metal ni `CAEmitterLayer` porque el foco está en la lógica de la
  interacción, no en el volumen.
- **Cantidad de partículas fija en 100** y colores en una paleta de tres, asignados de
  forma cíclica, no aleatoria.
- **Un solo toque.** El primer dedo manda; no hay soporte multitáctil ni gestos.
- **Al cambiar el tamaño de la vista las partículas se regeneran** en lugar de
  reescalar sus posiciones. La app está bloqueada a retrato, así que en la práctica
  solo ocurre una vez al arrancar.
- **Sin controles ni ajustes en pantalla**: los parámetros (número de partículas,
  radios, fuerza de atracción) son constantes en el código.
- La física libre no tiene fricción ni gravedad: las partículas mantienen su rapidez
  indefinidamente.

---

## Autor

Stephano Portella
