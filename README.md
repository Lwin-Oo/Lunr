# 🌙 Lunr – The AI Agent for Deep Focus & Aligned Progress

**Lunr** is a macOS-native productivity operating system designed to help you stay focused, aligned with your goals, and resilient against digital distractions. Powered by on-device AI and built with parallel computing principles, Lunr doesn’t just track your activity — it *understands* you.

---

## 🧠 What Is Lunr?

Lunr is your second brain — a contextual, motivational AI agent that learns from your behavior, helps you break down goals, and ensures your computer time aligns with your real-life ambitions. Whether you're coding, designing, or trying to finish that one thing, Lunr observes, reflects, and guides — all without cloud syncs or surveillance.

---

## 🚀 Core Features

- **🎯 Goal-Oriented Roadmaps**
  - Set personal or professional goals with realistic deadlines.
  - Automatically generate daily and weekly step-by-step roadmaps using LLMs.

- **📊 Usage Awareness**
  - Monitors your app sessions and uses AI to classify them into categories like `Code`, `Design`, `Entertainment`, `Social`, and more.
  - Provides daily summaries and behavioral insights.

- **💬 AI-Powered Encouragement**
  - Offers context-aware motivation generated based on your mood, the weather, and your focus level.
  - Utilizes local LLMs (via [Ollama](https://ollama.com)) — no internet or cloud required.

- **🔐 100% Private & Local**
  - All AI runs on-device. No external API calls. No surveillance. No data leaks.

---

## ⚙️ Engineered for Efficiency

Lunr is designed with performance in mind — optimized for Apple Silicon and real-time responsiveness.

- **🧵 Multi-threaded Monitoring Engine**
  - App usage logging and AI classification tasks run in parallel using GCD and timer threads.
  - Eliminates bottlenecks during real-time interaction tracking.

- **🧩 Modular AI Pipelines**
  - Tasks such as classification, motivation generation, and progress tracking run independently via asynchronous pipelines.
  - Encouragement and categorization never block the UI.

- **📈 Hardware-Conscious Performance**
  - Designed to harness the full power of Apple Silicon architecture.
  - LLMs run using `llm-optimized` models (e.g., Mistral) via the Ollama backend with multithreaded performance.

---

## 💻 Who Is Lunr For?

- Indie hackers, builders, and creators.
- Individuals working toward meaningful goals who want their computer to support — not sabotage — them.
- Anyone who values **privacy, productivity, and purpose**.

---

## 🛠 Developer Setup

> Requirements: macOS 13+, Xcode 15+

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/lunr.git
   cd lunr
   ```

2. Start the Ollama LLM backend:
   ```bash
   ollama run mistral
   ```

3. Open `Lunr.xcodeproj` in Xcode and run the app.

---

## 📚 Future Roadmap

- Local emotion detection via webcam (with explicit permission)
- Real-time distraction detection and intervention
- Optional encrypted cloud sync
- Plugin architecture for custom workflows (e.g., “Focus Mode for Designers”)

---

## 👨‍💻 Made by a Builder

Lunr was born out of frustration — and built with hope — by a creator who wanted tools that support ambition, not distract from it.

---

> “Your time is finite. Lunr makes sure you don’t waste it.”

