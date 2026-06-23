# 📱 Comparativa de Desarrollo Asistido por IA: GPS en Ionic vs Flutter

[![Ionic](https://img.shields.io/badge/Ionic-3880FF?style=for-the-badge&logo=ionic&logoColor=white)](https://ionicframework.com/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![OpenAI Codex](https://img.shields.io/badge/OpenAI_Codex-412991?style=for-the-badge&logo=openai&logoColor=white)](https://openai.com/)
[![Google Antigravity](https://img.shields.io/badge/Google_Antigravity-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://google.com/)

> **Deber de Inteligencia Artificial - ESFOT**
----
> **Estudiante:** Wilmer Ramos

### 🎥 Demostración Práctica
https://youtu.be/p-trhPa1rBs

---

## 🎯 Objetivo
Comparar la implementación del hardware de geolocalización (GPS) en frameworks multiplataforma (Ionic y Flutter), y analizar el desempeño, precisión y autonomía de las herramientas **OpenAI Codex** y **Google Antigravity** para el desarrollo de software asistido por Inteligencia Artificial.

---

## 📂 Estructura del Repositorio

El proyecto contiene 4 aplicaciones funcionales, divididas por la IA que las generó:

```text
📁 comparativa-gps-ia/
├── 📁 antigravity/
│   ├── 📁 flutter_gps/    (App Flutter creada por agente autónomo Antigravity)
│   └── 📁 ionic-gps/      (App Ionic creada por agente autónomo Antigravity)
├── 📁 codex/
│   ├── 📁 flutter_gps/    (App Flutter generada con alto razonamiento de Codex)
│   └── 📁 ionic-gps/      (App Ionic generada con alto razonamiento de Codex)
├── 📁 screenshots/        (Evidencias gráficas del funcionamiento y errores)
└── 📄 README.md
```
----

## 🛠️ Implementación Técnica y Manejo de Errores
Ambos desarrollos se compilaron y probaron nativamente en iOS utilizando Xcode en un entorno macOS (Apple Silicon M1).

Para garantizar la seguridad y evitar cierres inesperados (crashes) por políticas de privacidad de Apple, todas las aplicaciones incluyen:

### 1. Configuración Nativa: 
Implementación estricta de las llaves ```text NSLocationWhenInUseUsageDescription ```y ```text NSLocationAlwaysUsageDescription``` en el archivo ```text ios/Runner/Info.plist (Flutter)``` y ```text ios/App/Info.plist (Ionic)```.

### 2. Manejo de Excepciones en UI: 
Bloques ```text try/catch``` robustos que alertan al usuario visualmente si:

- El servicio de GPS del dispositivo está apagado.

- El usuario denegó los permisos de ubicación en el sistema.
----
## 1. Ecosistema Ionic (Angular + Capacitor)
### Librería: 
```text @capacitor/geolocation.```

### Proceso: 
Construcción web con ``` text npm run build ```y sincronización nativa mediante ```text npx cap sync ios```.

## 2. Ecosistema Flutter (Dart)
### Librería: 
```text geolocator``` (Añadido en pubspec.yaml).

### Proceso: 
Compilación directa mediante ```text flutter run``` hacia el dispositivo físico iOS / Simulador.

## Evidencia 

### Codex 

#### 1. Ionic GPS
![codexi](screenshots/codex-i-1.jpeg)

---
#### 2. Flutter GPS
![codexf](screenshots/codex-f-1.jpeg)

---

### Antigravity

#### 1. Ionic GPS
![antii](screenshots/anti-i-1.jpeg)

---
#### 2. Flutter GPS
![antii](screenshots/anti-f-1.jpeg)

---

## 🚀 Instrucciones de Ejecución Local
Para emular los proyectos en un entorno macOS con Xcode instalado:
``` text
# Clonar el repositorio
git clone https://github.com/WilmerRamos21/Comparativa-Apps-GPS-con-IA.git
cd comparativa-gps-ia

# Para ejecutar Flutter:
cd codex/flutter_gps
flutter pub get
flutter run

# Para ejecutar Ionic:
cd codex/ionic-gps
npm install
npm run build
npx cap sync ios
npx cap open ios # Ejecutar desde Xcode
```

## Conclusiones
Para finalizar, me quedo claro que el uso de la IA como un asistente de desarrollo de programas o aplicaciones, se ve notablemente acelerado en varios aspectos, uno de ellos es en el desarrollo de la lógica necesario y manejo de los errores y otro de ellos es en el diseño que tendrá el programa final.
A mi parecer la herramienta de Antigravity me resulto más eficaz en lo que sería el diseño de estilos y lógica, ya que me presento una aplicación con estilos mucho mejores que los de codex utilizando el mismo prompt en ambas, codex se enfocó mucho más en la lógica que en el diseño de la interfaz y antigravity hizo las dos cosas, también cabe recalcar que el razonamiento utilizado para el desarrollo de estas apps en codex se vio limitado ya que presentaba solo 3 niveles de pensamiento mientras que antigravity poseía alrededor de 10 niveles de pensamiento, inlcuyendo diferentes modelos de IA, lo que es Gemini Flash, Gemini Pro y Claude Sonnet que fue la cual use para el desarrollo de este software de aplicaciones móviles.

