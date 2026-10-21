---
language:
- en
license: other
license_name: acne04-academic-use-only
license_link: https://github.com/xpwu95/LDL
pretty_name: "ACNE04"
tags:
- medical
- dermatology
- acne
- severity-grading
- object-detection
- image-classification
- computer-vision
task_categories:
- image-classification
- object-detection
size_categories:
- 1K<n<10K
dataset_info:
  features:
  - name: image
    dtype: image
  - name: file_name
    dtype: string
  - name: level
    dtype: int32
  - name: severity
    dtype: string
  - name: lesion_count_label
    dtype: int32
  - name: num_lesions_annotated
    dtype: int32
  - name: lesion_boxes
    struct:
    - name: xmin
      list: int32
    - name: ymin
      list: int32
    - name: xmax
      list: int32
    - name: ymax
      list: int32
  - name: split
    dtype: string
  - name: fold_0_split
    dtype: string
  - name: fold_1_split
    dtype: string
  - name: fold_2_split
    dtype: string
  - name: fold_3_split
    dtype: string
  - name: fold_4_split
    dtype: string
  splits:
  - name: train
    num_bytes: 1129317681
    num_examples: 1457
  download_size: 1129317681
  dataset_size: 1129317681
configs:
- config_name: default
  data_files:
  - split: train
    path: data/train-*
---

<h1 align="center">ACNE04</h1>

<h3 align="center">1,457 facial acne photographs, rebuilt from the original ACNE04 release with clean image/label separation, verified 4-level Hayashi severity grades, and 18,983 lesion-level bounding box annotations.</h3>

<p align="center">
  <a href="https://huggingface.co/datasets/Layered-Labs/ACNE04">
    <img src="https://huggingface.co/datasets/huggingface/badges/resolve/main/dataset-on-hf-md.svg" alt="Dataset on HuggingFace"/>
  </a>
  &nbsp;
  <img src="https://img.shields.io/badge/license-academic--use--only-blue.svg" alt="License"/>
  &nbsp;
  <img src="https://img.shields.io/badge/source-ACNE04%20(ICCV%202019)-38BDF8.svg" alt="Source"/>
</p>

<p align="center">
  <img src="https://huggingface.co/datasets/Layered-Labs/ACNE04/resolve/main/banner.svg" alt="ACNE04" width="100%"/>
</p>

---

## Overview

This dataset packages the full ACNE04 corpus, 1,457 facial photographs graded for acne severity on the 4-level Hayashi scale, as a single, ready-to-load Hugging Face dataset. Every image is embedded directly in the parquet files alongside its full label set: severity grade (`level`/`severity`), the original lesion-count bucket label from the paper, and per-image lesion bounding boxes (18,983 total across the dataset). All 5 cross-validation folds used in the original paper are preserved as explicit train/test membership columns, plus a canonical `split` column (fold 0) for anyone who just wants a single train/test split.

The source images and labels come straight from the official release linked from the [xpwu95/LDL](https://github.com/xpwu95/LDL) GitHub repository (`Classification.tar` for images and grade labels, `Detection.tar` for the Pascal VOC lesion bounding boxes). Nothing was re-annotated or re-graded; the severity grades and lesion boxes are the original authors' annotations, joined row by row into a single table.

## Statement of Need

ACNE04 is normally distributed as two separate tar archives hosted on Google Drive (Classification: images + five pairs of plain-text train/test label files for 5-fold CV; Detection: a parallel Pascal VOC XML tree of lesion bounding boxes), which have to be manually downloaded, matched by filename, and joined. Several ACNE04 mirrors circulating on the Hub are incomplete (as few as 394 of the 1,457 images), drop the lesion bounding box annotations entirely, or repurpose the label files for unrelated tasks (e.g. text-to-image prompt captions) with no severity grade preserved. This dataset fixes that: the complete, original 1,457-image corpus, severity grades and lesion boxes joined per image, and every one of the paper's 5 CV folds retained so results are reproducible against the published benchmark.

## Intended Use

Intended for training and evaluating acne severity classification and lesion-detection models; benchmarking zero-shot or fine-tuned multimodal / VLM models on dermatological severity grading against the Hayashi ground truth; and research into scaling behavior, cost-efficiency, or bias in dermatology imaging AI. Suitable for academic research and model benchmarking. Not intended for clinical deployment or diagnostic use; this is a research dataset, not a validated clinical decision-support tool, and models trained on it should not be used to inform real patient care.

## Limitations

Ground truth reflects the original annotators' Hayashi grading from the source study and was not independently re-adjudicated. `lesion_count_label` is the raw label from the paper's text files and combines lesion count with severity bucket in a way that isn't fully documented by the original authors; use `level`/`severity` as the primary severity label. The 5 test folds are close to but not a perfectly disjoint partition of the 1,457 images (a handful of images appear in more than one fold's test set, a property of the original release, not introduced here); the canonical `split` column uses fold 0 only, which is a clean single split. Images vary in resolution, lighting, and framing since they were collected as routine clinical photographs, not under standardized imaging conditions.

## Dataset Structure

### Splits

| Split (canonical, fold 0) | Images |
|-------|--------|
| train | 1,165 |
| test | 292 |

### Severity distribution

| Severity | Level | Count |
|----------|-------|-------|
| mild | 0 | 513 |
| moderate | 1 | 633 |
| severe | 2 | 182 |
| very_severe | 3 | 129 |

### Features

| Column | Type | Description |
|--------|------|--------------|
| `image` | `Image` | The face photo. |
| `file_name` | `string` | Original filename. |
| `level` | `int32` | **Primary label.** Hayashi severity grade, 0-3. |
| `severity` | `string` | Human-readable grade name (`mild`, `moderate`, `severe`, `very_severe`). |
| `lesion_count_label` | `int32` | Original lesion-count bucket label from the paper's label files. |
| `num_lesions_annotated` | `int32` | Number of lesion bounding boxes annotated for this image. |
| `lesion_boxes` | `struct` | Per-lesion bounding boxes as parallel lists: `xmin`, `ymin`, `xmax`, `ymax` (pixel coordinates). Empty lists if no lesions were boxed. |
| `split` | `string` | `train`/`test`, canonical split (fold 0). |
| `fold_0_split` … `fold_4_split` | `string` | `train`/`test` membership for each of the paper's 5 CV folds. |

## Usage

```python
from datasets import load_dataset

ds = load_dataset("Layered-Labs/ACNE04")
print(ds)

example = ds["train"][0]
example["image"].show()
print("severity:", example["severity"], "(level", example["level"], ")")
print("lesion boxes:", example["num_lesions_annotated"])
```

### Example: canonical train/test split

```python
train = ds["train"].filter(lambda r: r["split"] == "train")
test = ds["train"].filter(lambda r: r["split"] == "test")
print(len(train), len(test))
```

### Example: full 5-fold cross-validation

```python
for fold in range(5):
    col = f"fold_{fold}_split"
    fold_train = ds["train"].filter(lambda r: r[col] == "train")
    fold_test = ds["train"].filter(lambda r: r[col] == "test")
    print(fold, len(fold_train), len(fold_test))
```

## Citation

If you use this dataset, please cite both this release and the original ACNE04 source:

```bibtex
@dataset{layeredlabs2026acne04,
  title     = {ACNE04},
  author    = {Ridwan, Abdullah and Hossain, Radhyyah and Noor, Saniya},
  year      = {2026},
  publisher = {Hugging Face},
  url       = {https://huggingface.co/datasets/Layered-Labs/ACNE04},
  note      = {Images and labels rebuilt from the original ACNE04 release}
}

@inproceedings{wu2019joint,
  title     = {Joint acne image grading and counting via label distribution learning},
  author    = {Wu, Xiaoping and Wen, Ni and Liang, Jie and Lai, Yu-Kun and She, Dongyu and Cheng, Ming-Ming and Yang, Jufeng},
  booktitle = {Proceedings of the IEEE/CVF International Conference on Computer Vision},
  pages     = {10642--10651},
  year      = {2019}
}
```

## License

The underlying ACNE04 dataset is released by the original authors for **academic/research use only**. For any other use, contact the original author, Xiaoping Wu (xpwu95@163.com), per the terms stated in the [official repository](https://github.com/xpwu95/LDL). This repackaging carries forward the same restriction: do not use this dataset for commercial purposes.
Maintained by [Layered Labs](https://layeredlabs.ai).
