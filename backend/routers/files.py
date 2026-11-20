from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends, APIRouter
from depends import get_db
from services.files import get_file,return_place_services

router = APIRouter()

@router.get("/get_coord")
async def return_place(db: AsyncSession = Depends(get_db)):
    return await return_place_services(db)

@router.get("/place")
async def get_place(lat: float, lon: float, db: AsyncSession = Depends(get_db)):
    return await get_file(lat,lon,db)