from datetime import datetime,timezone
import uuid
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import DateTime, Enum, ForeignKey, String, Text, Uuid

class Base(DeclarativeBase):
    pass

class UserDB(Base):

    __tablename__ = "Users"

    id : Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    email : Mapped[str]
    password : Mapped[str]
    fullname : Mapped[str]

    created_at : Mapped[datetime] = mapped_column(DateTime(timezone=True), default = lambda: datetime.now(timezone.utc))

class RefreshDB(Base):

    __tablename__ = "Tokens"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("Users.id",ondelete="CASCADE"), index=True)
    token_hash: Mapped[str] = mapped_column(unique=True)
    exp: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    family_id: Mapped[uuid.UUID] = mapped_column(Uuid, index=True)
    used: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    abs_edge: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    revoke_reason: Mapped[str | None] = mapped_column(Enum("Exit","Change password","repeat use","admin",name = "revoke_reason"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default = lambda: datetime.now(timezone.utc))

class AttachmentDB(Base):
    __tablename__ = "Attachments"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    filename: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    file_url: Mapped[str] = mapped_column(Text)        