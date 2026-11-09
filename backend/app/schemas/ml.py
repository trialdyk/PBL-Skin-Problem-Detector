"""Request and response schemas for acne severity prediction."""

from pydantic import BaseModel, Field


class ClassScore(BaseModel):
    """Probability of one model class (IGA) and the GEA grade it maps to."""

    label: str = Field(description="Model class name, e.g. IGA2.")
    grade: int = Field(ge=0, le=5, description="GEA grade for this class.")
    probability: float = Field(ge=0.0, le=1.0)


class ImagePrediction(BaseModel):
    """Prediction for a single uploaded photo."""

    filename: str = Field(description="Original upload filename.")
    top_label: str = Field(description="Most likely IGA class.")
    grade: int = Field(ge=0, le=5, description="GEA grade of the top class.")
    grade_label: str = Field(description="Indonesian grade label shown by the app.")
    predictions: list[ClassScore] = Field(description="All classes, in model order.")
    inference_ms: float = Field(description="Preprocessing plus inference time.")


class AggregatePrediction(BaseModel):
    """Element-wise mean prediction across the uploaded photos."""

    top_label: str
    grade: int = Field(ge=0, le=5)
    grade_label: str
    predictions: list[ClassScore]


class MlPredictResponse(BaseModel):
    """Body of a successful ``POST /ml/predict`` response."""

    model: str = Field(description="Model identifier.")
    images: list[ImagePrediction] = Field(description="Per-photo predictions.")
    aggregate: AggregatePrediction = Field(
        description="Mean probabilities; this is the grade the app displays.",
    )