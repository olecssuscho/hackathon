from pydantic import ConfigDict
from pydantic_settings import BaseSettings

class Settings(BaseSettings):

    DB_URL:str
    FRONTEND_URL:str
    REFRESH_TOKEN_TIME_DAYS:int
    ACCESS_TOKEN_TIME_MINUTES:int
    ALGORITHM:str
    SECRET_KEY:str
    ABS_DAY_LIFE:int
    CLOUDINARY_KEY:str
    CLOUDINARY_SECRET:str
    CLOUDINARY_NAME:str
    model_config = ConfigDict(env_file = ".env", env_file_encoding = "utf-8")

settings = Settings()