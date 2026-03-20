#!/usr/bin/env python3
import os
import subprocess
from pathlib import Path
from PIL import Image

def get_xdg_dir(type_name, default_path):
    try:
        path = subprocess.check_output(["xdg-user-dir", type_name]).decode("utf-8").strip()
        if path:
            return path
    except:
        pass
    return os.path.expanduser(default_path)

# Directories
WALLPAPER_DIR = os.path.join(get_xdg_dir("PICTURES", "~/Pictures"), "Wallpapers")
ANIMATION_DIR = os.path.join(get_xdg_dir("VIDEOS", "~/Videos"), "Animations")

WALL_THUMB_DIR = os.path.expanduser("~/.cache/wallpaper_thumbs")
ANIM_THUMB_DIR = os.path.expanduser("~/.cache/animation_thumbs")

# Thumbnail target dimensions
THUMB_WIDTH = 160
THUMB_HEIGHT = 90

# Ensure cache dirs exist
os.makedirs(WALL_THUMB_DIR, exist_ok=True)
os.makedirs(ANIM_THUMB_DIR, exist_ok=True)

def process_image(img_path, thumb_path):
    """Crops and resizes images to 16:9 using Pillow."""
    try:
        with Image.open(img_path) as im:
            im = im.convert("RGB")
            w, h = im.size
            target_aspect = THUMB_WIDTH / THUMB_HEIGHT
            src_aspect = w / h

            if src_aspect > target_aspect:
                new_w = int(h * target_aspect)
                left = (w - new_w) // 2
                im = im.crop((left, 0, left + new_w, h))
            else:
                new_h = int(w / target_aspect)
                top = (h - new_h) // 2
                im = im.crop((0, top, w, top + new_h))

            im = im.resize((THUMB_WIDTH, THUMB_HEIGHT), Image.LANCZOS)
            im.save(thumb_path, format="PNG")
            print(f"✓ Image Thumb: {os.path.basename(thumb_path)}")
    except Exception as e:
        print(f"✗ Image Error: {img_path} → {e}")

def process_video(vid_path, thumb_path):
    """Extracts a frame from video using ffmpeg, then crops/resizes it."""
    temp_frame = thumb_path + ".tmp.png"
    try:
        # Extract frame at 1 second mark
        subprocess.run([
            "ffmpeg", "-y", "-ss", "00:00:01", "-i", vid_path, 
            "-vframes", "1", "-q:v", "2", temp_frame
        ], check=True, capture_output=True)
        
        # Use existing Pillow logic to crop the frame to 16:9
        process_image(temp_frame, thumb_path)
        os.remove(temp_frame)
        print(f"✓ Video Thumb: {os.path.basename(thumb_path)}")
    except subprocess.CalledProcessError as e:
        print(f"✗ Video Error (ffmpeg): {vid_path} → {e}")
    except Exception as e:
        print(f"✗ Video Error: {vid_path} → {e}")

def main():
    # Process Wallpapers
    if os.path.exists(WALLPAPER_DIR):
        for file in os.listdir(WALLPAPER_DIR):
            if file.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
                src = os.path.join(WALLPAPER_DIR, file)
                dst = os.path.join(WALL_THUMB_DIR, file + ".png")
                if not os.path.exists(dst):
                    process_image(src, dst)

    # Process Animations
    if os.path.exists(ANIMATION_DIR):
        for file in os.listdir(ANIMATION_DIR):
            if file.lower().endswith((".mp4", ".mkv", ".webm", ".mov")):
                src = os.path.join(ANIMATION_DIR, file)
                dst = os.path.join(ANIM_THUMB_DIR, file + ".png")
                if not os.path.exists(dst):
                    process_video(src, dst)

if __name__ == "__main__":
    main()