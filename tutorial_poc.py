#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
tutorial_poc.py - NarratoAI Tutorial Proof of Concept

This script demonstrates how to use NarratoAI through Docker for video 
subtitle and narration generation tasks.
"""

import os
import sys
import subprocess
from pathlib import Path


def print_section(title):
    """Print a formatted section header."""
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70 + "\n")


def check_prerequisites():
    """Check if prerequisites are installed."""
    print_section("Checking Prerequisites")
    
    tools = [
        ("Docker", ["docker", "--version"]),
        ("FFmpeg", ["ffmpeg", "-version"]),
    ]
    
    results = {}
    for name, cmd in tools:
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                print(f"✓ {name} is installed")
                version = result.stdout.split('\n')[0]
                print(f"  {version}")
                results[name] = True
            else:
                print(f"✗ {name} not found or not working")
                results[name] = False
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print(f"✗ {name} not installed")
            results[name] = False
    
    return all(results.values())


def demo_workflow():
    """Show the complete workflow."""
    print_section("Complete Video Processing Workflow")
    
    workflow = '''
NarratoAI automates the following workflow:

1. VIDEO INPUT
   ├── Upload your video file (MP4, MOV, AVI, etc.)
   └── System extracts audio and analyzes content

2. SCRIPT GENERATION
   ├── Analyze video content using AI
   ├── Generate narration script
   └── Optionally: Use custom script

3. SUBTITLE PROCESSING
   ├── Speech-to-text (STT) for existing audio
   └── Generate synchronized subtitles

4. NARRATION (TTS)
   ├── Choose voice style
   ├── Generate synthetic narration
   └── Match timing with video

5. VIDEO SYNTHESIS
   ├── Combine original video with narration
   ├── Add subtitles overlay
   └── Export final video

6. OUTPUT
   └── Download processed video with subtitles
'''
    print(workflow)


def demo_docker_usage():
    """Demo Docker usage."""
    print_section("Docker Usage Examples")
    
    docker_commands = '''
# Build the Docker image
cd NarratoAI
docker build -t narratoai:latest .

# Start container with docker-compose
docker-compose up -d

# Or start manually with volume mounts
docker run -d \\
    --name narratoai \\
    -p 11170:8501 \\
    -v $(pwd)/storage:/NarratoAI/storage:rw \\
    -v $(pwd)/config.toml:/NarratoAI/config.toml:rw \\
    -v $(pwd)/resource:/NarratoAI/resource:rw \\
    narratoai:latest

# View logs
docker logs -f narratoai

# Access the web UI
open http://localhost:11170

# Stop the container
docker-compose down
or
docker stop narratoai

# View health status
curl http://localhost:11170/_stcore/health
'''

    print(docker_commands)


def demo_config():
    """Show configuration options."""
    print_section("Configuration Options")
    
    config_info = '''
Key configuration settings in config.toml:

[llm]
# LLM provider configuration
provider = "openai"  # openai, anthropic, azure, ollama
api_key = "your-api-key"
model = "gpt-4o"

[stt]
# Speech-to-text settings
provider = "whisper"
model = "large-v3"
language = "zh"

[tts]
# Text-to-speech settings
provider = "edge"
voice = "zh-CN-XiaoxiaoNeural"

[video]
# Video processing settings
output_format = "mp4"
video_quality = "high"
add_subtitles = true
'''

    print(config_info)


def demo_python_api():
    """Demo Python API usage."""
    print_section("Python API Examples")
    
    api_code = '''
# Example: Using NarratoAI programmatically

import os
import sys
sys.path.insert(0, os.path.dirname(__file__))

from app.services import task as tm
from app.models.schema import VideoClipParams, VideoAspect
from app.config import config

# Configure the task
params = VideoClipParams(
    video_path="path/to/video.mp4",
    script="Your narration script here",
    voice_style="zh-CN-XiaoxiaoNeural",
    subtitle_language="zh",
    aspect=VideoAspect.portrait
)

# Start the task
task_id = tm.start_subclip_unified(task_id="my-task", params=params)

# Monitor progress
from app.services import state as sm
task = sm.state.get_task(task_id)
print(f"Progress: {task.get('progress', 0)}%")
'''

    print(api_code)


def demo_supported_features():
    """Show supported features."""
    print_section("Supported Features")
    
    features = '''
✅ VIDEO PROCESSING
   - Multiple format support (MP4, MOV, AVI, etc.)
   - Audio extraction and processing
   - Hardware acceleration support (FFmpeg)

✅ SCRIPT GENERATION
   - AI-powered script generation
   - Custom script input
   - Script editing and refinement

✅ SPEECH RECOGNITION (STT)
   - Whisper-based recognition
   - Multi-language support
   - Speaker diarization

✅ SYNTHETIC NARRATION (TTS)
   - Multiple voice styles
   - Speed and pitch control
   - Voice cloning support

✅ SUBTITLE SUPPORT
   - SRT format
   - Custom styling
   - Position adjustment

✅ OUTPUT OPTIONS
   - Multiple video formats
   - Subtitle embedding
   - Separate subtitle files
'''

    print(features)


def demo_storage():
    """Show storage requirements."""
    print_section("Storage and Requirements")
    
    storage = '''
Directory Structure:
/storage
├── temp/          # Temporary files during processing
├── tasks/         # Task metadata and progress
├── json/          # JSON outputs (scripts, metadata)
├── narration_scripts/  # Generated narration scripts
└── drama_analysis/     # Video analysis results

Disk Space:
- Minimum: 10GB for models
- Recommended: 50GB+
- For heavy usage: 100GB+

RAM:
- Minimum: 8GB
- Recommended: 16GB+
- With GPU: 8GB (GPU memory offloads CPU)
'''

    print(storage)


def demo_quick_start():
    """Quick start guide."""
    print_section("Quick Start Guide")
    
    quick_start = '''
1. PREREQUISITES
   ✓ Docker installed
   ✓ FFmpeg installed
   ✓ 50GB+ free disk space
   ✓ 16GB+ RAM recommended

2. INITIAL SETUP
   git clone https://github.com/linyqh/NarratoAI.git
   cd NarratoAI
   cp config.example.toml config.toml
   # Edit config.toml with your API keys

3. BUILD AND RUN
   docker build -t narratoai:latest .
   docker-compose up -d

4. FIRST USE
   Open http://localhost:11170
   Upload a video file
   Configure settings
   Click "Generate Video"

5. MONITORING
   docker logs -f narratoai
   Check http://localhost:11170 for progress
'''

    print(quick_start)


def main():
    """Main entry point."""
    print("\n" + "/NarratoAI Tutorial POC".center(70, "="))
    print("  Automated Video Subtitle & Narration Tool".center(70))
    print("=" * 70)

    # Check prerequisites
    prereq_ok = check_prerequisites()

    # Run demos
    demo_workflow()
    demo_docker_usage()
    demo_config()
    demo_python_api()
    demo_supported_features()
    demo_storage()
    demo_quick_start()

    # Summary
    print_section("Quick Start Summary")

    summary = '''
1. SETUP
   - Install Docker and FFmpeg
   - Clone the repository
   - Configure API keys in config.toml

2. DEPLOY
   - Build: docker build -t narratoai:latest .
   - Run: docker-compose up -d

3. USE
   - Access http://localhost:11170
   - Upload video and configure settings
   - Generate processed video

For more information, visit: https://github.com/linyqh/NarratoAI
'''

    print(summary)

    if not prereq_ok:
        print("\n" + "!" * 70)
        print("  WARNING: Some prerequisites are missing. Please install them first.")
        print("!" * 70 + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
