# Stage 1: Build
FROM node:24-slim AS build

# تثبيت pnpm وأدوات البناء الضرورية
RUN corepack enable && corepack prepare pnpm@9.6.0 --activate
RUN apt-get update && apt-get install -y python3 make g++ git

WORKDIR /app

# نسخ ملفات المشروع
COPY . .

# تثبيت الاعتماديات (بدون تنفيذ سكريبت build لأنه غير موجود)
RUN pnpm install --frozen-lockfile

# تنفيذ deploy للمشروع المطلوب (api)
RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

# --- الحل الجذري لمشكلة Git ---
RUN mkdir -p /prod/api/.git/objects /prod/api/.git/refs && \
    echo "ref: refs/heads/master" > /prod/api/.git/HEAD

# Stage 2: Production
FROM node:24-slim AS api

WORKDIR /app

# نسخ المجلد الجاهز من مرحلة البناء
COPY --from=build /prod/api /app

# إعداد متغيرات البيئة
ENV NODE_ENV=production
ENV COBALT_VERSION=10.0.0
ENV API_URL=https://ok-download.onrender.com

# تثبيت ffmpeg للتعامل مع الفيديو
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

EXPOSE 3000

# أمر التشغيل (تأكد أن الملف الرئيسي هو src/index.js)
CMD ["node", "src/index.js"]
