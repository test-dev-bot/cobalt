# Stage 1: Build
FROM node:24-slim AS build

# تثبيت pnpm وأدوات البناء الضرورية
RUN corepack enable && corepack prepare pnpm@9.6.0 --activate
RUN apt-get update && apt-get install -y python3 make g++ git

WORKDIR /app

# نسخ ملفات الاعتماديات فقط لتسريع البناء
COPY pnpm-lock.yaml package.json ./
COPY . .

# تثبيت الاعتماديات وبناء المشروع
RUN pnpm install --frozen-lockfile
RUN pnpm run build

# تنفيذ deploy للمشروع المطلوب (api) إلى مجلد منفصل
RUN pnpm deploy --filter=@imput/cobalt-api --prod /prod/api

# --- الحل الجذري لمشكلة Git ---
# إنشاء هيكل Git وهمي داخل مجلد الإنتاج لإرضاء مكتبة git-rev-sync
RUN mkdir -p /prod/api/.git/objects /prod/api/.git/refs && \
    echo "ref: refs/heads/master" > /prod/api/.git/HEAD

# Stage 2: Production
FROM node:24-slim AS api

WORKDIR /app

# نسخ المجلد الجاهز من مرحلة البناء (يحتوي الآن على .git الوهمي)
COPY --from=build /prod/api /app

# إعداد متغيرات البيئة الأساسية داخل الدوكر
ENV NODE_ENV=production
ENV COBALT_VERSION=10.0.0
ENV API_URL=https://ok-download.onrender.com

# التأكد من وجود ffmpeg (إذا كان التطبيق يحتاجه)
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

EXPOSE 3000

# أمر التشغيل النهائي
CMD ["node", "src/index.js"]
