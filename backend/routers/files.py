from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends, APIRouter
from depends import get_db
from services.files import get_file

router = APIRouter()

@router.get("/place")
async def get_place(lat: float, lon: float, db: AsyncSession = Depends(get_db)):
    return await get_file(lat,lon,db)