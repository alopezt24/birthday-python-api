# Database table definition
from sqlalchemy import Column, String, Date
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class User(Base):
    """Table to store users and their birthdays"""
    __tablename__ = "users"
    
    username = Column(String(50), primary_key=True)
    date_of_birth = Column(Date, nullable=False)