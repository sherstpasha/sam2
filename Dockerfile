# Используем базовый образ с PyTorch и CUDA
ARG BASE_IMAGE=pytorch/pytorch:2.3.1-cuda12.1-cudnn8-runtime

FROM ${BASE_IMAGE}

# Переменные окружения
ENV APP_ROOT=/opt/sam2
ENV PYTHONUNBUFFERED=1
ENV SAM2_BUILD_CUDA=0
ENV MODEL_SIZE=base_plus

# Установка системных зависимостей
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libavutil-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    pkg-config \
    build-essential \
    libffi-dev \
    python3-pip  # Устанавливаем pip для установки Jupyter

# Установка Python зависимостей
COPY setup.py .
COPY README.md .

RUN pip install --upgrade pip setuptools
RUN pip install -e ".[interactive-demo]"

# Установка Jupyter
RUN pip install jupyter

# Установка ffmpeg для работы с видео
RUN rm /opt/conda/bin/ffmpeg && ln -s /bin/ffmpeg /opt/conda/bin/ffmpeg

# Создание рабочей директории
RUN mkdir ${APP_ROOT}

# Копируем файлы
COPY demo/backend/server ${APP_ROOT}/server
COPY sam2 ${APP_ROOT}/server/sam2

# Загружаем контрольные точки модели
ADD https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_large.pt ${APP_ROOT}/checkpoints/sam2.1_hiera_large.pt

# Устанавливаем рабочую директорию
WORKDIR ${APP_ROOT}/server

# Отключаем требования пароля и токена
RUN mkdir -p /root/.jupyter && \
    echo "c.NotebookApp.token = ''" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.password = ''" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.allow_origin = '*'" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.open_browser = False" >> /root/.jupyter/jupyter_notebook_config.py && \
    echo "c.NotebookApp.port = 8888" >> /root/.jupyter/jupyter_notebook_config.py

# Запуск Jupyter без токена и пароля
CMD ["jupyter", "notebook", "--ip='0.0.0.0'", "--port=8888", "--no-browser", "--allow-root"]
