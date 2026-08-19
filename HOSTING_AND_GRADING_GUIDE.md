# 🚀 Hosting & Grading Submission Guide for G28 Web App

This guide explains how to host your **G28 Stepper Motor Controller Web App** online for **free** so you can get a public link to submit for your assignment grading.

---

## 🌟 Option 1: GitHub Pages (Recommended — 100% Free & Automatic)

If your code is stored in a GitHub repository, GitHub Pages will automatically host your web app:

1. **Push your code to GitHub**:
   ```bash
   git add .
   git commit -m "Add G28 Stepper Controller Web App"
   git push origin main
   ```

2. **Enable GitHub Pages**:
   - Go to your repository on [github.com](https://github.com).
   - Click **Settings** (tab at the top).
   - On the left sidebar, click **Pages**.
   - Under **Build and deployment** > **Source**, select **GitHub Actions** (or select **Deploy from a branch** -> branch `main` / root `/`).
   - Click **Save**.

3. **Get your Live Grading Link**:
   - Within 1–2 minutes, your website will be live at:
     ```
     https://<your-github-username>.github.io/<repo-name>/
     ```
   - Copy this URL and submit it as your project link!

---

## ⚡ Option 2: Vercel (Fast 1-Click Deployment)

1. Go to [vercel.com](https://vercel.com) and log in with GitHub.
2. Click **Add New...** > **Project**.
3. Import your `g28` GitHub repository.
4. Leave default settings (Root directory `./`, Framework preset: Other) and click **Deploy**.
5. Within 15 seconds, Vercel will give you a live production URL like:
   ```
   https://g28-stepper-controller.vercel.app
   ```

---

## 🌐 Option 3: Netlify (Drag-and-Drop or Git)

1. Go to [netlify.com](https://netlify.com) and log in.
2. Go to **Sites** and drag-and-drop the project folder directly onto the page, OR click **Import from Git**.
3. Netlify will instantly deploy it and give you a public URL like:
   ```
   https://g28-stepper-controller.netlify.app
   ```

---

## 🎯 What Graders & Evaluators Can Test (Grading Checklist)

When your professor, TA, or grader opens your link in any browser (Chrome, Edge, Safari, Firefox, or Mobile):

1. **Realistic Stepper Physics Visualizer**:
   - Custom 2D Canvas rendering the NEMA 17 motor with 200-step toothed rotor.
   - Dynamic 8-pole stator electromagnets that light up in real-time as phase steps fire.
   - Live speed (RPM) and direction (CW / CCW) status indicators.

2. **Operating Mode 1 — Velocity Controller (M1)**:
   - Interactive 0–80 RPM throttle slider with real-time numeric readouts.
   - Direction selectors (`FORWARD [F]` & `REVERSE [R]`).
   - Smooth continuous rotation physics.

3. **Operating Mode 2 — Angle Position Mode (M2)**:
   - Interactive 360° Target Angle Compass Dial (click and drag to aim angle).
   - Tactical numeric keypad (`7-8-9`, `4-5-6`, `1-2-3`, `C`, `0`, `MOVE`).
   - Fine jog step buttons (`+1°`, `+10°`, `-1°`, `-10°`).
   - Quick preset angle chips (`+15°`, `+45°`, `+90°`, `+180°`, etc.).
   - Zero Tare Origin button (`Z`).

4. **Safety Features — Emergency Stop (S)**:
   - Big tactical Emergency Stop button that halts motion instantly, cuts simulated coil power, and displays a red warning banner.
   - Toggle button to resume normal operation.

5. **Diagnostic Oscilloscope & Serial Monitor**:
   - 4-Channel digital oscilloscope tracking stator pulse waveforms ($A+, B+, A-, B-$) in real-time.
   - Live timestamped serial communication console displaying TX/RX protocol packets (e.g. `<STATUS,speed,dir,stop,angle,mode>`).
   - Custom command sender for manual testing (`V50`, `G180`, `F`, `R`, `S`, `Z`).

6. **Web Audio Stepper Acoustic Feedback**:
   - Synthesizes realistic stepper motor acoustic frequency based on RPM stepping rate ($f = \text{RPM} \times \frac{200}{60}\text{ Hz}$).
   - Toggleable sound button.

7. **Hardware Ready**:
   - Evaluators with real ESP32 / Arduino Uno hardware can click **CONNECT** in Chrome/Edge to connect directly over **Web Bluetooth** or **Web Serial USB Cable**!
