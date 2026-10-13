
import os
import json
import hmac
import hashlib
import secrets
from datetime import timezone
from typing import Any, Optional

import mysql.connector
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv()

app = FastAPI(
    title="ASHA Sarthi API",
    version="2.1.0",
    description="Login, Registration, Messages, Notifications and SMS Simulation",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =====================================================
# DATABASE CONNECTION
# =====================================================

def get_connection():
    required = [
        "MYSQLHOST",
        "MYSQLUSER",
        "MYSQLPASSWORD",
        "MYSQLDATABASE",
    ]
    missing = [key for key in required if not os.getenv(key)]

    if missing:
        raise RuntimeError(
            "Missing .env variables: " + ", ".join(missing)
        )

    return mysql.connector.connect(
        host=os.getenv("MYSQLHOST"),
        port=int(os.getenv("MYSQLPORT", "3306")),
        user=os.getenv("MYSQLUSER"),
        password=os.getenv("MYSQLPASSWORD"),
        database=os.getenv("MYSQLDATABASE"),
        connection_timeout=10,
    )


# =====================================================
# DATABASE TABLES
# =====================================================

def ensure_schema():
    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS app_users (
                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(191) NOT NULL,
                role VARCHAR(80) NOT NULL,
                email VARCHAR(191) NOT NULL UNIQUE,
                password_hash VARCHAR(256) NOT NULL,
                village VARCHAR(191),
                mobile VARCHAR(40),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)

        cur.execute("""
            CREATE TABLE IF NOT EXISTS sync_records (
                owner_id VARCHAR(191) NOT NULL,
                entity VARCHAR(80) NOT NULL,
                record_id VARCHAR(191) NOT NULL,
                payload JSON NOT NULL,
                deleted BOOLEAN NOT NULL DEFAULT FALSE,
                updated_at TIMESTAMP(6) NOT NULL
                    DEFAULT CURRENT_TIMESTAMP(6)
                    ON UPDATE CURRENT_TIMESTAMP(6),
                PRIMARY KEY (owner_id, entity, record_id)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)

        cur.execute("""
            CREATE TABLE IF NOT EXISTS app_messages (
                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                sender_role VARCHAR(50) NOT NULL,
                sender_name VARCHAR(191),
                sender_contact VARCHAR(100),
                receiver_role VARCHAR(50) NOT NULL,
                receiver_name VARCHAR(191),
                receiver_contact VARCHAR(100),
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)

        cur.execute("""
            CREATE TABLE IF NOT EXISTS app_notifications (
                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                recipient_role VARCHAR(50) NOT NULL,
                recipient_contact VARCHAR(100),
                title VARCHAR(191) NOT NULL,
                body TEXT NOT NULL,
                is_read TINYINT(1) NOT NULL DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)

        cur.execute("""
            CREATE TABLE IF NOT EXISTS sms_simulations (
                id BIGINT AUTO_INCREMENT PRIMARY KEY,
                beneficiary_name VARCHAR(191) NOT NULL,
                beneficiary_mobile VARCHAR(40) NOT NULL,
                worker_contact VARCHAR(100) NOT NULL,
                message TEXT NOT NULL,
                reply VARCHAR(30) DEFAULT '',
                status VARCHAR(40) NOT NULL DEFAULT 'sent',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """)

        db.commit()

    finally:
        cur.close()
        db.close()


@app.on_event("startup")
def startup():
    ensure_schema()


# =====================================================
# AUTHENTICATION
# =====================================================

def normalize_role(role: str) -> str:
    role = role.strip().lower()

    aliases = {
        "asha worker": "asha worker",
        "asha_worker": "asha worker",
        "asha-worker": "asha worker",
        "supervisor": "supervisor",
        "beneficiary": "beneficiary",
    }

    return aliases.get(role, role)


ALLOWED_ROLES = {
    "asha worker",
    "supervisor",
    "beneficiary",
}


def hash_password(
    password: str,
    salt: Optional[str] = None,
) -> str:
    salt = salt or secrets.token_hex(16)

    hashed = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        bytes.fromhex(salt),
        200000,
    ).hex()

    return f"{salt}${hashed}"


def verify_password(
    password: str,
    stored_hash: str,
) -> bool:
    try:
        salt, expected_hash = stored_hash.split("$", 1)

        actual_hash = hash_password(
            password,
            salt,
        ).split("$", 1)[1]

        return hmac.compare_digest(
            actual_hash,
            expected_hash,
        )

    except (ValueError, TypeError):
        return False


class RegisterRequest(BaseModel):
    name: str = Field(min_length=1, max_length=191)
    role: str = Field(min_length=1, max_length=80)
    email: str = Field(min_length=3, max_length=191)
    password: str = Field(min_length=6, max_length=128)
    village: Optional[str] = None
    mobile: Optional[str] = None


class LoginRequest(BaseModel):
    email: str = Field(min_length=3, max_length=191)
    password: str = Field(min_length=1, max_length=128)
    role: str = Field(min_length=1, max_length=80)


@app.post("/register")
def register_user(data: RegisterRequest):
    email = data.email.strip().lower()
    role = normalize_role(data.role)

    if role not in ALLOWED_ROLES:
        raise HTTPException(
            status_code=400,
            detail="Unsupported role",
        )

    if not data.name.strip():
        raise HTTPException(
            status_code=400,
            detail="Name is required",
        )

    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute(
            """
            INSERT INTO app_users
                (name, role, email, password_hash, village, mobile)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                data.name.strip(),
                role,
                email,
                hash_password(data.password),
                data.village,
                data.mobile,
            ),
        )

        user_id = cur.lastrowid
        db.commit()

        return {
            "success": True,
            "message": "Registration successful",
            "data": {
                "id": user_id,
                "name": data.name.strip(),
                "role": role,
                "email": email,
                "village": data.village,
                "mobile": data.mobile,
            },
        }

    except mysql.connector.IntegrityError as exc:
        db.rollback()

        if exc.errno == 1062:
            raise HTTPException(
                status_code=409,
                detail="An account with this email already exists",
            )

        raise HTTPException(
            status_code=400,
            detail="Registration failed",
        )

    finally:
        cur.close()
        db.close()


@app.post("/login")
def login_user(data: LoginRequest):
    email = data.email.strip().lower()
    role = normalize_role(data.role)

    db = get_connection()
    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT id, name, role, email, password_hash,
                   village, mobile
            FROM app_users
            WHERE email = %s
            LIMIT 1
            """,
            (email,),
        )

        user = cur.fetchone()

        if (
            not user
            or normalize_role(user["role"]) != role
            or not verify_password(
                data.password,
                user["password_hash"],
            )
        ):
            raise HTTPException(
                status_code=401,
                detail="Invalid email, password or role",
            )

        user.pop("password_hash", None)

        return {
            "success": True,
            "message": "Login successful",
            "data": user,
        }

    finally:
        cur.close()
        db.close()


# =====================================================
# SYNC API AUTHENTICATION
# =====================================================

def require_sync_token(
    authorization: Optional[str] = Header(default=None),
):
    expected = os.getenv("SYNC_API_KEY", "")

    if len(expected) < 32:
        raise HTTPException(
            status_code=503,
            detail="Configure SYNC_API_KEY with at least 32 characters",
        )

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing bearer token",
        )

    supplied = authorization[7:].strip()

    if not hmac.compare_digest(supplied, expected):
        raise HTTPException(
            status_code=401,
            detail="Invalid API token",
        )

    return True


class SyncRecord(BaseModel):
    owner_id: str = Field(min_length=1, max_length=191)
    entity: str = Field(min_length=1, max_length=80)
    record_id: str = Field(min_length=1, max_length=191)
    payload: dict[str, Any]
    deleted: bool = False


# =====================================================
# REQUEST MODELS
# =====================================================

class MessageRequest(BaseModel):
    sender_role: str
    sender_name: Optional[str] = None
    sender_contact: Optional[str] = None
    receiver_role: str
    receiver_name: Optional[str] = None
    receiver_contact: Optional[str] = None
    message: str = Field(min_length=1, max_length=5000)


class SimulationRequest(BaseModel):
    beneficiary_name: str = Field(min_length=1, max_length=191)
    beneficiary_mobile: str = Field(min_length=8, max_length=40)
    worker_contact: str = Field(min_length=1, max_length=100)
    message: str = Field(min_length=1, max_length=5000)


class SimulationReply(BaseModel):
    reply: str


# =====================================================
# NOTIFICATION HELPER
# =====================================================

def save_notification(role, contact, title, body):
    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute(
            """
            INSERT INTO app_notifications
                (recipient_role, recipient_contact, title, body)
            VALUES (%s, %s, %s, %s)
            """,
            (role, contact, title, body),
        )
        db.commit()

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()
        db.close()


# =====================================================
# ROOT AND HEALTH
# =====================================================

@app.get("/")
def root():
    return {
        "service": "ASHA Sarthi API",
        "status": "running",
        "mode": "free_sms_simulation",
        "docs": "/docs",
    }


@app.get("/health")
def health():
    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute("SELECT 1")
        cur.fetchone()

        return {
            "status": "ok",
            "database": "connected",
        }

    finally:
        cur.close()
        db.close()


# =====================================================
# CLOUD SYNC
# =====================================================

@app.post(
    "/sync/push",
    dependencies=[Depends(require_sync_token)],
)
def push_record(record: SyncRecord):
    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute(
            """
            INSERT INTO sync_records
                (owner_id, entity, record_id, payload, deleted)
            VALUES (%s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                payload = VALUES(payload),
                deleted = VALUES(deleted),
                updated_at = CURRENT_TIMESTAMP(6)
            """,
            (
                record.owner_id,
                record.entity,
                record.record_id,
                json.dumps(record.payload, ensure_ascii=False),
                record.deleted,
            ),
        )

        db.commit()

        return {
            "success": True,
            "record_id": record.record_id,
        }

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()
        db.close()


@app.get(
    "/sync/pull",
    dependencies=[Depends(require_sync_token)],
)
def pull_records(
    owner_id: str = Query(min_length=1),
    limit: int = Query(default=500, ge=1, le=2000),
):
    db = get_connection()
    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT entity, record_id, payload, deleted, updated_at
            FROM sync_records
            WHERE owner_id = %s
            ORDER BY updated_at DESC
            LIMIT %s
            """,
            (owner_id, limit),
        )

        rows = cur.fetchall()

        for row in rows:
            if isinstance(row["payload"], str):
                row["payload"] = json.loads(row["payload"])

            row["deleted"] = bool(row["deleted"])

            if row["updated_at"]:
                row["updated_at"] = (
                    row["updated_at"]
                    .replace(tzinfo=timezone.utc)
                    .isoformat()
                )

        return {
            "records": rows,
            "count": len(rows),
        }

    finally:
        cur.close()
        db.close()


# =====================================================
# MESSAGES
# =====================================================

@app.post("/messages")
def create_message(data: MessageRequest):
    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute(
            """
            INSERT INTO app_messages
                (sender_role, sender_name, sender_contact,
                 receiver_role, receiver_name, receiver_contact, message)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            """,
            (
                data.sender_role,
                data.sender_name,
                data.sender_contact,
                data.receiver_role,
                data.receiver_name,
                data.receiver_contact,
                data.message,
            ),
        )

        message_id = cur.lastrowid
        db.commit()

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()
        db.close()

    try:
        save_notification(
            data.receiver_role,
            data.receiver_contact,
            "New message",
            f"{data.sender_name or data.sender_role}: {data.message}",
        )
    except Exception:
        pass

    return {
        "success": True,
        "id": message_id,
        "message": "Message saved. No SMS was sent.",
    }


@app.get("/messages")
def get_messages(
    role: str = Query(min_length=1),
    contact: Optional[str] = None,
    limit: int = Query(default=200, ge=1, le=1000),
):
    db = get_connection()
    cur = db.cursor(dictionary=True)

    try:
        if contact:
            cur.execute(
                """
                SELECT * FROM app_messages
                WHERE (sender_role = %s AND sender_contact = %s)
                   OR (receiver_role = %s AND receiver_contact = %s)
                ORDER BY created_at DESC
                LIMIT %s
                """,
                (role, contact, role, contact, limit),
            )
        else:
            cur.execute(
                """
                SELECT * FROM app_messages
                WHERE sender_role = %s OR receiver_role = %s
                ORDER BY created_at DESC
                LIMIT %s
                """,
                (role, role, limit),
            )

        rows = cur.fetchall()

        for row in rows:
            if row.get("created_at"):
                row["created_at"] = row["created_at"].isoformat()

        return {"messages": rows}

    finally:
        cur.close()
        db.close()


# =====================================================
# NOTIFICATIONS
# =====================================================

@app.get("/notifications")
def get_notifications(
    role: str = Query(min_length=1),
    contact: Optional[str] = None,
    limit: int = Query(default=200, ge=1, le=1000),
):
    db = get_connection()
    cur = db.cursor(dictionary=True)

    try:
        if contact:
            cur.execute(
                """
                SELECT * FROM app_notifications
                WHERE recipient_role = %s
                  AND (recipient_contact = %s OR recipient_contact IS NULL)
                ORDER BY created_at DESC
                LIMIT %s
                """,
                (role, contact, limit),
            )
        else:
            cur.execute(
                """
                SELECT * FROM app_notifications
                WHERE recipient_role = %s
                ORDER BY created_at DESC
                LIMIT %s
                """,
                (role, limit),
            )

        rows = cur.fetchall()

        for row in rows:
            if row.get("created_at"):
                row["created_at"] = row["created_at"].isoformat()

        return {"notifications": rows}

    finally:
        cur.close()
        db.close()


@app.post("/notifications/{notification_id}/read")
def mark_notification_read(notification_id: int):
    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute(
            "UPDATE app_notifications SET is_read = 1 WHERE id = %s",
            (notification_id,),
        )
        db.commit()

        if cur.rowcount == 0:
            raise HTTPException(
                status_code=404,
                detail="Notification not found",
            )

        return {"success": True}

    finally:
        cur.close()
        db.close()


# =====================================================
# FREE SMS SIMULATION
# No real SMS is sent by these endpoints.
# =====================================================

@app.post("/sms-simulation/send")
def simulate_sms_send(data: SimulationRequest):
    db = get_connection()
    cur = db.cursor()

    try:
        cur.execute(
            """
            INSERT INTO sms_simulations
                (beneficiary_name, beneficiary_mobile,
                 worker_contact, message, status)
            VALUES (%s, %s, %s, %s, 'sent')
            """,
            (
                data.beneficiary_name,
                data.beneficiary_mobile,
                data.worker_contact,
                data.message,
            ),
        )

        sms_id = cur.lastrowid
        db.commit()

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()
        db.close()

    try:
        save_notification(
            "beneficiary",
            data.beneficiary_mobile,
            "Demo SMS received",
            data.message,
        )
    except Exception:
        pass

    return {
        "success": True,
        "simulation": True,
        "id": sms_id,
        "status": "sent",
        "message": "Demo SMS saved. No real SMS was sent.",
    }


@app.post("/sms-simulation/{sms_id}/reply")
def simulate_sms_reply(sms_id: int, data: SimulationReply):
    reply = data.reply.strip().upper()

    status_map = {
        "YES": "completed",
        "NO": "not_completed",
        "RESCHEDULE": "reschedule_requested",
    }

    if reply not in status_map:
        raise HTTPException(
            status_code=400,
            detail="Reply must be YES, NO, or RESCHEDULE",
        )

    db = get_connection()
    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            "SELECT * FROM sms_simulations WHERE id = %s",
            (sms_id,),
        )
        sms = cur.fetchone()

        if not sms:
            raise HTTPException(
                status_code=404,
                detail="Simulation not found",
            )

        cur.execute(
            """
            UPDATE sms_simulations
            SET reply = %s, status = %s
            WHERE id = %s
            """,
            (reply, status_map[reply], sms_id),
        )
        db.commit()

        worker_contact = sms["worker_contact"]
        beneficiary = sms["beneficiary_name"]

    except Exception:
        db.rollback()
        raise

    finally:
        cur.close()
        db.close()

    try:
        save_notification(
            "asha worker",
            worker_contact,
            "SMS Simulation Reply",
            f"{beneficiary} replied {reply}. Status: {status_map[reply]}",
        )
    except Exception:
        pass

    return {
        "success": True,
        "simulation": True,
        "id": sms_id,
        "reply": reply,
        "status": status_map[reply],
        "message": "Demo reply saved successfully.",
    }


@app.get("/sms-simulation")
def list_simulated_sms(
    limit: int = Query(default=100, ge=1, le=500),
):
    db = get_connection()
    cur = db.cursor(dictionary=True)

    try:
        cur.execute(
            """
            SELECT * FROM sms_simulations
            ORDER BY id DESC
            LIMIT %s
            """,
            (limit,),
        )

        rows = cur.fetchall()

        for row in rows:
            if row.get("created_at"):
                row["created_at"] = row["created_at"].isoformat()

        return {
            "success": True,
            "messages": rows,
            "count": len(rows),
        }

    finally:
        cur.close()
        db.close()
