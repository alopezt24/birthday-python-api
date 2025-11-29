# Database connection setup
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import Base

# Get database URL from environment variable
DATABASE_URL = os.getenv("DATABASE_URL","postgresql://postgres:postgres@localhost:5432/birthdays")

# Create database engine
engine = create_engine(DATABASE_URL)

# Create session factory
SessionLocal = sessionmaker(bind=engine)

def init_db():
    """Create all tables in database"""
    Base.metadata.create_all(bind=engine)

def get_db():
    """Get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()