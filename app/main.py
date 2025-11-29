# Main FastAPI application
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import date, datetime
import re

from db import init_db, get_db
from models import User

app = FastAPI()

# Request body model
class UserRequest(BaseModel):
    dateOfBirth: str  # Format: YYYY-MM-DD

# Create tables when app starts
@app.on_event("startup")
def startup():
    init_db()

@app.get("/")
def root():
    return {"status": "ok"}

@app.put("/hello/{username}", status_code=204)
def save_user(username: str, user_data: UserRequest, db: Session = Depends(get_db)):
    """Save or update user birthday"""
    
    # Check username has only letters
    if not re.match(r'^[a-zA-Z]+$', username):
        raise HTTPException(status_code=400, detail="Username must contain only letters")
    
    # Convert string to date
    try:
        birth_date = datetime.strptime(user_data.dateOfBirth, '%Y-%m-%d').date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    
    # Check date is in the past
    if birth_date >= date.today():
        raise HTTPException(status_code=400, detail="Date must be before today")
    
    # Check if user exists
    existing_user = db.query(User).filter(User.username == username).first()
    
    if existing_user:
        # Update existing user
        existing_user.date_of_birth = birth_date
    else:
        # Create new user
        new_user = User(username=username, date_of_birth=birth_date)
        db.add(new_user)
    
    db.commit()
    return None

@app.get("/hello/{username}")
def get_birthday_message(username: str, db: Session = Depends(get_db)):
    """Get birthday message for user"""
    
    # Check username format
    if not re.match(r'^[a-zA-Z]+$', username):
        raise HTTPException(status_code=400, detail="Username must contain only letters")
    
    # Find user in database
    user = db.query(User).filter(User.username == username).first()
    
    if not user:
        raise HTTPException(status_code=404, detail=f"User {username} not found")
    
    # Calculate days until birthday
    today = date.today()
    
    # Get birthday for this year
    birthday_this_year = date(today.year, user.date_of_birth.month, user.date_of_birth.day)
    
    # If birthday already happened, use next year
    if birthday_this_year < today:
        birthday_this_year = date(today.year + 1, user.date_of_birth.month, user.date_of_birth.day)
    
    # Calculate difference in days
    days_until = (birthday_this_year - today).days
    
    # Build message
    if days_until == 0:
        message = f"Hello, {username}! Happy birthday!"
    else:
        message = f"Hello, {username}! Your birthday is in {days_until} day(s)"
    
    return {"message": message}

@app.get("/health")
def health():
    """Health check endpoint"""
    return {"status": "healthy"}