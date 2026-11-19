from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import users,files
from config import settings
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:5500",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:5500",
        "http://127.0.0.1:8080",
        settings.FRONTEND_URL
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(users.router)
app.include_router(files.router)

@app.get("/")
def root():
    return {"Message":"Hello"}

app.include_router(users.router)
