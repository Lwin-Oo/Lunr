
# 🌙 Lunr – The AI Agent for Deep Focus & Aligned Progress

**Lunr** is a macOS-native productivity operating system that keeps you focused, aligned with your goals, and resilient against digital distractions. Powered by on-device AI and built with parallel computing principles, Lunr doesn’t just track your activity — it *understands* you.

---

## 🧠 What Is Lunr?

Lunr is your second brain — a contextual, motivational AI agent that learns from your behavior, helps you break down goals, and ensures your computer time reflects your real-life ambitions. Whether you’re coding, designing, or just trying to finish that one damn thing, Lunr watches, reflects, and guides — without cloud syncs or surveillance.

---

## 🚀 Core Features

- **🎯 Goal-Oriented Roadmaps**
  - Set personal or professional goals with realistic deadlines.
  - Automatically generate daily and weekly step-by-step roadmaps using LLMs.

- **📊 Usage Awareness**
  - Monitors your app sessions and classifies them using AI into categories like `Code`, `Design`, `Entertainment`, `Social`, and more.
  - Gives you daily summaries and behavioral analysis.

- **💬 AI-Powered Encouragement**
  - Context-aware motivation generated from your mood, today’s weather, and focus.
  - Uses local LLMs (via [Ollama](https://ollama.com)) — no internet or cloud calls.

- **🔐 100% Private & Local**
  - All AI runs on-device. No external API calls. No surveillance. No leaks.

---

## ⚙️ Built with Parallel Computing in Mind

Lunr isn’t just smart — it’s efficient.

- **🧵 Multi-threaded Monitoring Engine**
  - App usage logging and LLM classification tasks are parallelized using GCD and timer threads.
  - Prevents bottlenecks during real-time interaction tracking.

- **🧩 Modular AI Pipelines**
  - Tasks like classification, encouragement generation, and progress parsing run independently using asynchronous pipelines.
  - Encouragement and categorization don’t block UI or user tasks.

- **📈 Hardware-Conscious Performance**
  - Designed to leverage Apple Silicon’s architecture.
  - LLMs run via `llm-optimized` models (e.g., Mistral) through Ollama backend using multiple system threads for fast response.

---

## 💻 Who Is It For?

- Indie hackers, builders, creators.
- People working toward a goal and want their computer to help, not sabotage.
- Those who care about **privacy, productivity, and purpose**.

---

## 🛠 How to Run (Dev Setup)

> Requires macOS 13+, Xcode 15+

1. Clone the repo:
   ```bash
   git clone https://github.com/your-org/lunr.git
   cd lunr
````

2. Start Ollama LLM backend:

   ```bash
   ollama run mistral
   ```

3. Open `Lunr.xcodeproj` and run the app.

---

## 📚 Future Directions

* Local emotion detection using webcam input (with permission)
* Real-time distraction intervention (AI-based blocking)
* Cloud-sync for encrypted data (opt-in only)
* Plugin system for customizable workflows (e.g., “Focus Mode for Designers”)

---

## 👨‍💻 Built by a Builder

Lunr was built from frustration — and hope — by real a real creator who wanted his tools to support him, not just distract him.

---

> “Your time is finite. Lunr makes sure you don’t waste it.”

---


