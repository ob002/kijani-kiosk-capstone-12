from flask import Flask, jsonify
import os

app = Flask(__name__)
ENVIRONMENT = os.getenv("ENVIRONMENT", "unknown")

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "environment": ENVIRONMENT}), 200

@app.route('/checkout')
def checkout():
    return jsonify({"message": "Ticket purchased successfully!", "environment": ENVIRONMENT}), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
