from fastapi import FastAPI

app = FastAPI(
    title="PUV Passenger Counting API",
    description="Backend API for Public Utility Vehicle Passenger Counting Using YOLO-Based Computer Vision",
    version="1.0.0"
)



@app.get("/health")
def health_check():
    return {"status": "ok"}