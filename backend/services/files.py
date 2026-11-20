from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException
from schemas.dbmodels import AttachmentDB

async def get_file(lat: float, lon: float, db: AsyncSession):

    result = await db.execute(select(AttachmentDB)
            .filter(AttachmentDB.lat == lat, AttachmentDB.lon == lon))
    item = result.scalar_one_or_none()

    if not item:
        raise HTTPException(status_code=404, detail="Точку не знайдено")

    return {
        "name": item.name,
        "photo_url": item.file_url,
        "wiki_url": item.wiki_url,
        "description_short_uk" : item.destiption_uk,
        "description_short_en" : item.destiption_en,
    }

async def return_place_services(db:AsyncSession):
    result = await db.execute(select(AttachmentDB))
    items = result.scalars()
    res=[]
    for e in items:
        res.append((e.lat,e.lon,e.filename,e.file_url,e.wiki_url,e.destiption_uk,e.destiption_en))
    return res