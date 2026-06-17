Looking at the EcoTrack README as reference, here's the clean ExamFort README:

---

# 🏰 ExamFort

> **Secure. Smart. Seamless.**
> A full-stack exam management platform built with FastAPI & React.

![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?style=for-the-badge&logo=fastapi)
![React](https://img.shields.io/badge/React-Vite-61DAFB?style=for-the-badge&logo=react)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

🌐 **Live Demo:** https://examfort.vercel.app/

---

## 📱 About ExamFort

ExamFort is a comprehensive exam management platform designed for schools and institutions to run mock exams, assign seats, manage paper vault security, and monitor student performance in real time.

Admins can create mock exams, view leaderboards, monitor paper leaks, generate seating plans, and secure exam content. Students can log in, view their dashboard, attempt exams, and review results.

---

## 📸 Screenshots

<table>
  <tr>
    <td><img src="Screenshots/AdminLogin.png" width="100%" alt="Admin Login"/><p align="center"><b>Admin Login</b></p></td>
    <td><img src="Screenshots/AdminGeneratedSeating.png" width="100%" alt="Generated Seating"/><p align="center"><b>Generated Seating</b></p></td>
  </tr>
  <tr>
    <td><img src="Screenshots/AdminMockBoard.png" width="100%" alt="Mock Board"/><p align="center"><b>Mock Board</b></p></td>
    <td><img src="Screenshots/AdminPaperLeak.png" width="100%" alt="Paper Leak"/><p align="center"><b>Paper Leak Tracker</b></p></td>
  </tr>
  <tr>
    <td><img src="Screenshots/AdminPaperVault.png" width="100%" alt="Paper Vault"/><p align="center"><b>Paper Vault</b></p></td>
    <td><img src="Screenshots/AdminSmartSeat.png" width="100%" alt="Smart Seat"/><p align="center"><b>Seat Smart</b></p></td>
  </tr>
  <tr>
    <td><img src="Screenshots/StudentDashboard.png" width="100%" alt="Student Dashboard"/><p align="center"><b>Student Dashboard</b></p></td>
    <td><img src="Screenshots/StudentPageDowlnload.png" width="100%" alt="Student Download"/><p align="center"><b>Download Page</b></p></td>
  </tr>
  <tr>
    <td><img src="Screenshots/StudentQuiz.png" width="100%" alt="Student Quiz"/><p align="center"><b>Student Quiz</b></p></td>
    <td><img src="Screenshots/StudentResults.png" width="100%" alt="Student Results"/><p align="center"><b>Results View</b></p></td>
  </tr>
</table>

---

## ✨ Features

- ✅ Admin authentication and protected dashboard
- ✅ Mock exam creation and leaderboard tracking
- ✅ Student login and exam access portal
- ✅ Paper vault tracking and leak monitoring
- ✅ Smart seating assignment and export
- ✅ Real-time score display and detailed reports
- ✅ REST API backend with frontend integration

---

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| **FastAPI** | Backend REST API |
| **React + Vite** | Frontend UI |
| **Supabase** | Database & Auth |
| **PostgreSQL** | Database (via Supabase) |
| **Groq API** | AI features |
| **Render** | Backend deployment |
| **Vercel** | Frontend deployment |

---

## 🚀 Setup Instructions

### Backend
```bash
cd backend
python -m venv venv
venv\Scripts\activate       # Windows
source venv/bin/activate    # Mac/Linux
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend
```bash
cd frontend
npm install
npm run dev
```

Create `frontend/.env`:
```
VITE_API_BASE_URL=https://examfort.onrender.com
```

---

## 📁 Project Structure

```
examfort/
├── backend/
│   ├── requirements.txt
│   └── app/
│       ├── core/        # config, security, supabase client
│       ├── models/      # schemas
│       ├── routers/     # auth, leaktrace, mockboard, papervault, seatsmart, student
│       └── services/    # crypto, fingerprint, groq, seating
├── frontend/
│   └── src/
│       ├── api/         # axios client
│       ├── components/  # Navbar, ProtectedRoute
│       ├── context/     # AuthContext
│       └── pages/       # Admin & Student views
└── Screenshots/
```

---

## 📄 License

MIT License — Copyright (c) 2026
