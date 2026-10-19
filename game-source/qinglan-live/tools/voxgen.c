// 1mm 密集体素角色生成器：分片体素化 + 贪心合并 + 1 体素描边壳
// 输出：out/voxmesh.bin  格式 "VX1\0" u32 nMesh { u32 vc, ic ; f32 pos[3] f32 nrm[3] f32 col[3] ; u32 idx }
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>

#define VS 0.001
#define OX -0.55f
#define OZ -0.35f
#define NX 1100
#define NZ 700
#define NSLAB 100
#define NYH (NSLAB + 2)

static unsigned char *G;   // 颜色网格
static unsigned char *O;   // 描边网格（膨胀 1 体素）
static float ybase = 0.0f;

#define GI(x,y,z) (((size_t)(y) * NZ + (z)) * NX + (x))

static inline float wx(int x) { return OX + (x + 0.5f) * VS; }
static inline float wz(int z) { return OZ + (z + 0.5f) * VS; }
static inline float wy(int y) { return ybase + (y - 1 + 0.5f) * VS; }
static inline int ix_(float x) { return (int)floorf((x - OX) / VS); }
static inline int iz_(float z) { return (int)floorf((z - OZ) / VS); }
static inline int iy_(float y) { return (int)floorf((y - ybase) / VS) + 1; }
static inline int Y0(float y) { int t = iy_(y); return t < 0 ? 0 : t; }
static inline int Y1(float y) { int t = iy_(y); return t > NYH-1 ? NYH-1 : t; }

// ── 色板 ─────────────────────────────────────────────
static float PAL[][3] = {
	{0,0,0},
	{0.05f,0.23f,0.29f},  // 1  深袍
	{0.09f,0.44f,0.50f},  // 2  正袍
	{0.18f,0.71f,0.75f},  // 3  亮袍
	{0.95f,0.97f,0.96f},  // 4  白
	{1.00f,0.76f,0.23f},  // 5  金
	{0.79f,0.54f,0.12f},  // 6  暗金
	{0.78f,0.19f,0.23f},  // 7  朱红
	{0.96f,0.76f,0.61f},  // 8  肤
	{0.85f,0.60f,0.47f},  // 9  肤影
	{0.07f,0.06f,0.11f},  // 10 发
	{0.16f,0.14f,0.22f},  // 11 发亮
	{0.84f,0.90f,0.96f},  // 12 钢
	{0.25f,0.89f,0.70f},  // 13 玉
	{0.98f,0.99f,1.00f},  // 14 眼白
	{0.17f,0.44f,0.56f},  // 15 虹膜
	{0.03f,0.03f,0.05f},  // 16 瞳
	{0.10f,0.13f,0.19f},  // 17 靴
	{0.02f,0.02f,0.03f},  // 18 描边黑
	{0.90f,0.56f,0.49f},  // 19 腮红
	{0.66f,0.13f,0.18f},  // 20 唇
};
#define NPAL 21

static inline void put(int x, int y, int z, int c) {
	if (x < 0 || x >= NX || y < 0 || y >= NYH || z < 0 || z >= NZ) return;
	G[GI(x,y,z)] = (unsigned char)c;
}
static inline int solid(int x, int y, int z) {
	if (x < 0 || x >= NX || y < 0 || y >= NYH || z < 0 || z >= NZ) return 0;
	return G[GI(x,y,z)] > 0;
}

// ── 体块 ─────────────────────────────────────────────
static void f_box(float cx, float cy, float cz, float hx, float hy, float hz, int c) {
	int x0 = ix_(cx-hx), x1 = ix_(cx+hx), y0 = iy_(cy-hy), y1 = iy_(cy+hy), z0 = iz_(cz-hz), z1 = iz_(cz+hz);
	if (y0 < 0) y0 = 0; if (y1 >= NYH) y1 = NYH-1;
	for (int y = y0; y <= y1; y++) { float Y = wy(y);
		if (fabsf(Y-cy) > hy) continue;
		for (int z = z0; z <= z1; z++) { float Z = wz(z); if (fabsf(Z-cz) > hz) continue;
			for (int x = x0; x <= x1; x++) { float X = wx(x); if (fabsf(X-cx) > hx) continue; put(x,y,z,c); } } }
}
static void f_ellip(float cx, float cy, float cz, float rx, float ry, float rz, int c) {
	int x0 = ix_(cx-rx), x1 = ix_(cx+rx), y0 = iy_(cy-ry), y1 = iy_(cy+ry), z0 = iz_(cz-rz), z1 = iz_(cz+rz);
	if (y0 < 0) y0 = 0; if (y1 >= NYH) y1 = NYH-1;
	for (int y = y0; y <= y1; y++) { float ty = (wy(y)-cy)/ry; if (fabsf(ty) > 1) continue;
		for (int z = z0; z <= z1; z++) { float tz = (wz(z)-cz)/rz; if (fabsf(tz) > 1) continue;
			float s = 1 - ty*ty - tz*tz; if (s < 0) continue;
			float xr = rx * sqrtf(s);
			for (int x = x0; x <= x1; x++) { if (fabsf(wx(x)-cx) <= xr) put(x,y,z,c); } } }
}
static void f_caps(float ax, float ay, float az, float bx, float by, float bz, float r, int c) {
	float lo[3] = {fminf(ax,bx)-r, fminf(ay,by)-r, fminf(az,bz)-r};
	float hi[3] = {fmaxf(ax,bx)+r, fmaxf(ay,by)+r, fmaxf(az,bz)+r};
	int x0 = ix_(lo[0]), x1 = ix_(hi[0]), y0 = iy_(lo[1]), y1 = iy_(hi[1]), z0 = iz_(lo[2]), z1 = iz_(hi[2]);
	if (y0 < 0) y0 = 0; if (y1 >= NYH) y1 = NYH-1;
	float abx = bx-ax, aby = by-ay, abz = bz-az;
	float l2 = abx*abx + aby*aby + abz*abz;
	for (int y = y0; y <= y1; y++) for (int z = z0; z <= z1; z++) for (int x = x0; x <= x1; x++) {
		float px = wx(x)-ax, py = wy(y)-ay, pz = wz(z)-az;
		float t = 0; if (l2 > 1e-9f) { t = (px*abx+py*aby+pz*abz)/l2; if (t<0) t=0; if (t>1) t=1; }
		float dx = px-abx*t, dy = py-aby*t, dz = pz-abz*t;
		if (dx*dx+dy*dy+dz*dz <= r*r) put(x,y,z,c);
	}
}
// 圆台：y0..y1，半径 r0→r1，z 方向 squash
static void f_cone(float y0f, float y1f, float r0, float r1, float sq, int c) {
	int y0 = iy_(y0f), y1 = iy_(y1f);
	if (y0 < 0) y0 = 0; if (y1 >= NYH) y1 = NYH-1;
	float R = fmaxf(r0, r1);
	for (int y = y0; y <= y1; y++) {
		float Y = wy(y); if (Y < y0f || Y > y1f) continue;
		float t = (Y - y0f) / fmaxf(y1f - y0f, 1e-6f);
		float r = r0 + (r1 - r0) * t;
		int x0 = ix_(-r), x1 = ix_(r), z0 = iz_(-r*sq), z1 = iz_(r*sq);
		for (int z = z0; z <= z1; z++) { float Z = wz(z)/sq;
			for (int x = x0; x <= x1; x++) { float X = wx(x); if (X*X + Z*Z <= r*r) put(x,y,z,c); } }
	}
}
static void paint(int x, int y, int z, int c) {
	if (x < 0 || x >= NX || y < 0 || y >= NYH || z < 0 || z >= NZ) return;
	unsigned char *p = &G[GI(x,y,z)];
	if (*p > 0) *p = (unsigned char)c;
}

// ── 角色本体（1mm） ──────────────────────────────────
static void face_art(void) {
	// 脸是平面：在 z = -0.062 的前层上按 2D 画五官
	float cy = 1.615f, zface = -0.062f;
	for (int y = Y0(cy-0.11f); y <= Y1(cy+0.11f); y++) {
		float v = wy(y) - cy;
		for (int x = ix_(-0.10f); x <= ix_(0.10f); x++) {
			float u = wx(x);
			int zz = iz_(zface);
			int hit = -1;
			for (int z = zz; z <= zz + 4; z++) if (solid(x,y,z)) { hit = z; break; }
			if (hit < 0) continue;
			float au = fabsf(u);
			int col = 0;
			float eu = au - 0.038f;                 // 到眼心的水平距离
			float radii = 0.026f, radv = 0.017f;
			// 眼睛
			if ((eu*eu)/(radii*radii) + (v-0.006f)*(v-0.006f)/(radv*radv) <= 1.0f) {
				col = 14;
				float du = u - (u > 0 ? 0.038f : -0.038f) + 0.002f;
				float dv = v - 0.002f;
				if (du*du + dv*dv <= 0.013f*0.013f) col = 15;
				if (du*du + dv*dv <= 0.0065f*0.0065f) col = 16;
				float hu = u - (u > 0 ? 0.038f : -0.038f) - 0.004f, hv = v - 0.009f;
				if (hu*hu + hv*hv <= 0.0045f*0.0045f) col = 14;
			}
			// 上眼睑（粗黑）
			if (eu*eu/(0.030f*0.030f) + (v-0.006f)*(v-0.006f)/(radv*radv) <= 1.0f && v > 0.010f && v < 0.024f) col = 10;
			// 眉
			if (au > 0.010f && au < 0.072f && v > 0.044f + (au-0.010f)*0.10f && v < 0.052f + (au-0.010f)*0.10f) col = 10;
			// 睫外角
			if (eu*eu/(0.034f*0.034f) + (v-0.004f)*(v-0.004f)/(0.024f*0.024f) <= 0.18f && v > -0.008f) col = 10;
			// 鼻影
			if (fabsf(u) < 0.010f && v > -0.020f && v < -0.008f) col = 9;
			// 唇
			if (fabsf(u) < 0.015f && v > -0.050f && v < -0.040f && fabsf(u)*fabsf(u)/0.00023f + (v+0.045f)*(v+0.045f)/0.000025f <= 1.2f) col = 20;
			// 朱砂
			if (fabsf(u) < 0.008f && fabsf(v - 0.036f) < 0.008f) col = 7;
			// 腮红
			if (au > 0.045f && au < 0.070f && v > -0.035f && v < -0.012f) col = 19;
			if (col) paint(x, y, hit, col);
		}
	}
}

static void build_scene(void) {
	// 靴
	for (int s = -1; s <= 1; s += 2) {
		float bx = 0.085f * s;
		f_box(bx, 0.042f, -0.035f, 0.055f, 0.042f, 0.098f, 17);
		f_box(bx, 0.075f, -0.115f, 0.048f, 0.022f, 0.022f, 17);
		f_box(bx, 0.088f, -0.005f, 0.058f, 0.010f, 0.078f, 5);   // 靴口金边
	}
	// 腿
	for (int s = -1; s <= 1; s += 2) {
		float bx = 0.085f * s;
		f_caps(bx, 0.09f, 0.0f, bx, 0.52f, 0.0f, 0.050f, 1);
		f_caps(bx, 0.50f, 0.0f, bx, 0.92f, 0.0f, 0.070f, 1);
	}
	// 裙摆（带褶）
	f_cone(0.50f, 1.00f, 0.305f, 0.170f, 0.80f, 4);
	for (int y = Y0(0.50f); y <= Y1(1.00f); y++) {
		float Y = wy(y); if (Y < 0.50f || Y > 1.00f) continue;
		float t = (Y - 0.50f) / 0.50f;
		float r = 0.305f + (0.170f - 0.305f) * t;
		for (int z = iz_(-r*0.8f); z <= iz_(r*0.8f); z++) for (int x = ix_(-r); x <= ix_(r); x++) {
			float X = wx(x), Z = wz(z) / 0.8f;
			float d2 = X*X + Z*Z;
			if (d2 > r*r || d2 < (r-0.02f)*(r-0.02f)) continue;
			float th = atan2f(Z, X);
			float pleat = cosf(th * 7.0f);
			int col = 4;
			if (Y > 0.735f) col = (pleat > 0.2f) ? 2 : 1;      // 青袍褶皱明暗
			else if (Y > 0.72f) col = 3;
			if (Y < 0.512f) col = 5;                            // 金边
			else if (Y < 0.545f) col = (pleat > 0.0f) ? 5 : 6;  // 回纹带
			else if (Y < 0.60f && fmodf(fabsf(X)*1000.0f, 26.0f) < 4.0f) col = 6; // 细纹
			paint(x, y, z, col);
		}
	}
	// 前襟金条
	for (int y = Y0(0.55f); y <= Y1(0.99f); y++) {
		float Y = wy(y); float t = (Y - 0.50f) / 0.50f;
		float r = 0.305f + (0.170f - 0.305f) * t;
		int z = iz_(-r * 0.8f);
		for (int x = ix_(-0.011f); x <= ix_(0.011f); x++) for (int d = 0; d < 3; d++) paint(x, y, z - d, 5);
	}
	// 躯干
	f_cone(1.00f, 1.30f, 0.175f, 0.200f, 0.78f, 3);
	f_cone(1.30f, 1.44f, 0.200f, 0.185f, 0.78f, 3);
	// 交领：白内衫 V + 金边
	for (int y = Y0(1.02f); y <= Y1(1.45f); y++) {
		float Y = wy(y); if (Y < 1.02f || Y > 1.45f) continue;
		float t = (Y - 1.02f) / 0.43f;
		float half = 0.012f + 0.075f * t;
		for (int x = ix_(-half-0.012f); x <= ix_(half+0.012f); x++) {
			float X = wx(x);
			int z = -1;
			for (int zz = iz_(-0.22f); zz <= iz_(0.05f); zz++) if (solid(x,y,zz)) { z = zz; break; }
			if (z < 0) continue;
			float ax = fabsf(X);
			if (ax <= half) paint(x, y, z, 4);
			else if (ax <= half + 0.010f) paint(x, y, z, 5);
			else if (ax <= half + 0.016f) paint(x, y, z, 1);
			for (int d = 1; d < 3; d++) { if (ax <= half) paint(x,y,z-d,4); }
		}
	}
	// 领口金边 + 肩饰
	f_cone(1.402f, 1.442f, 0.190f, 0.186f, 0.80f, 5);
	// 腰带
	f_cone(0.955f, 1.012f, 0.183f, 0.180f, 0.80f, 7);
	for (int y = Y0(0.965f); y <= Y1(1.002f); y++) {
		float Y = wy(y);
		for (int x = ix_(-0.20f); x <= ix_(0.20f); x++) for (int z = iz_(-0.21f); z <= iz_(-0.10f); z++) {
			if (!solid(x,y,z)) continue;
			float X = wx(x);
			if (fabsf(X) > 0.030f && fmodf(fabsf(X)*1000.0f, 12.0f) < 3.0f) paint(x,y,z,6);
		}
	}
	f_ellip(0.0f, 0.984f, -0.176f, 0.030f, 0.030f, 0.020f, 13);
	// 宽袖
	for (int s = -1; s <= 1; s += 2) {
		float sx = 0.185f * s;
		f_caps(sx, 1.395f, 0.0f, 0.268f * s, 1.02f, -0.012f, 0.090f, 3);
		// 袖口
		f_ellip(0.268f * s, 1.015f, -0.012f, 0.094f, 0.028f, 0.094f, 5);
		// 袖褶
		for (int y = Y0(1.05f); y <= Y1(1.38f); y++) for (int z = iz_(-0.20f); z <= iz_(0.15f); z++)
			for (int x = ix_(sx-0.10f); x <= ix_(sx+0.10f); x++) {
				if (!solid(x,y,z)) continue;
				float X = wx(x), Y = wy(y), Z = wz(z);
				float th = atan2f(Z - (Y-1.2f)*0.05f, X - sx);
				if (fmodf(fabsf(th) * 3.5f, 1.0f) < 0.22f) paint(x,y,z,2);
			}
		// 手
		f_ellip(0.280f * s, 0.975f, -0.018f, 0.046f, 0.052f, 0.044f, 8);
	}
	// 颈
	f_caps(0.0f, 1.415f, 0.0f, 0.0f, 1.505f, 0.0f, 0.048f, 8);
	// 头（前面切平）
	f_ellip(0.0f, 1.615f, 0.0f, 0.106f, 0.126f, 0.106f, 8);
	{
		int zc = iz_(-0.062f);
		for (int y = Y0(1.48f); y <= Y1(1.75f); y++) for (int z = 0; z < zc; z++) for (int x = 0; x < NX; x++) {
			if (G[GI(x,y,z)] == 8) G[GI(x,y,z)] = 0;   // 切掉 z<-0.062 的部分 → 平面脸
		}
		// 切面补一层肤色
		for (int y = Y0(1.48f); y <= Y1(1.75f); y++) for (int x = ix_(-0.09f); x <= ix_(0.09f); x++) {
			if (solid(x,y,zc+1)) put(x,y,zc,8);
		}
	}
	// 头发：包住头顶后侧，露出平面脸
	for (int y = Y0(1.44f); y <= Y1(1.79f); y++) {
		float Y = wy(y);
		for (int z = iz_(-0.16f); z <= iz_(0.16f); z++) for (int x = ix_(-0.135f); x <= ix_(0.135f); x++) {
			float dx = wx(x)/0.118f, dy = (Y-1.618f)/0.140f, dz = (wz(z)-0.012f)/0.124f;
			if (dx*dx + dy*dy + dz*dz > 1.0f) continue;
			if (wz(z) < -0.050f && Y < 1.688f) continue;   // 脸露出来
			if (fabsf(wx(x)) < 0.075f && Y < 1.688f && wz(z) < -0.02f) continue;
			put(x, y, z, 10);
		}
	}
	// 发丝高光
	for (int y = Y0(1.50f); y <= Y1(1.78f); y++) for (int z = iz_(-0.14f); z <= iz_(0.14f); z++) for (int x = ix_(-0.13f); x <= ix_(0.13f); x++) {
		if (G[GI(x,y,z)] != 10) continue;
		float th = atan2f(wx(x), wz(z));
		if (fmodf(fabsf(th) * 9.0f, 1.0f) < 0.18f) paint(x,y,z,11);
	}
	// 鬓发
	for (int s = -1; s <= 1; s += 2) f_caps(0.098f*s, 1.690f, -0.018f, 0.092f*s, 1.540f, 0.010f, 0.022f, 10);
	// 马尾
	f_caps(0.0f, 1.720f, 0.100f, 0.02f, 1.26f, 0.155f, 0.040f, 10);
	// 抹额
	f_cone(1.680f, 1.702f, 0.112f, 0.110f, 1.0f, 5);
	f_ellip(0.0f, 1.691f, -0.108f, 0.018f, 0.011f, 0.008f, 13);
	// 剑鞘
	f_caps(0.115f, 1.020f, 0.135f, -0.075f, 0.560f, 0.175f, 0.026f, 17);
	f_caps(0.115f, 1.020f, 0.135f, 0.128f, 1.100f, 0.130f, 0.028f, 5);
	// 五官
	face_art();
}

// ── 贪心合并 ─────────────────────────────────────────
typedef struct { float *p; float *n; float *c; uint32_t *idx; size_t vc, ic, capv, capi; } Mesh;
static Mesh M, OUT;

static void m_reserve(Mesh *m, size_t v, size_t i) {
	if (m->vc + v > m->capv) { m->capv = (m->vc + v) * 2 + 1024; m->p = realloc(m->p, m->capv*3*sizeof(float)); m->n = realloc(m->n, m->capv*3*sizeof(float)); m->c = realloc(m->c, m->capv*3*sizeof(float)); }
	if (m->ic + i > m->capi) { m->capi = (m->ic + i) * 2 + 1536; m->idx = realloc(m->idx, m->capi*sizeof(uint32_t)); }
}
static void m_quad(Mesh *m, float x0,float y0,float z0, float ux,float uy,float uz, float vx,float vy,float vz,
                   float w, float h, float nx,float ny,float nz, int col) {
	m_reserve(m, 4, 6);
	size_t base = m->vc;
	float px[4], py[4], pz[4];
	float corners[4][3] = {{0,0},{1,0},{1,1},{0,1}};
	for (int k = 0; k < 4; k++) {
		px[k] = x0 + ux*w*corners[k][0] + vx*h*corners[k][1];
		py[k] = y0 + uy*w*corners[k][0] + vy*h*corners[k][1];
		pz[k] = z0 + uz*w*corners[k][0] + vz*h*corners[k][1];
		for (int j = 0; j < 3; j++) {
			float *pp = (j==0)?&px[k]:(j==1)?&py[k]:&pz[k];
			m->p[m->vc*3 + j] = *pp;
			m->n[m->vc*3 + j] = (j==0)?nx:(j==1)?ny:nz;
			m->c[m->vc*3 + j] = PAL[col][j];
		}
		m->vc++;
	}
	uint32_t *o = m->idx + m->ic;
	o[0]=base; o[1]=base+1; o[2]=base+2; o[3]=base; o[4]=base+2; o[5]=base+3;
	m->ic += 6;
}

// 对每个轴做贪心合并；is_outline=1 时用 O 网格
static void greedy(int d, int is_outline) {
	int dims[3] = {NX, NYH, NZ};
	int stride[3] = {1, NX*NZ, NX};
	int a = (d+1)%3, b = (d+2)%3;
	int nu = dims[a], nv = dims[b];
	int *mask = malloc(sizeof(int) * nu * nv);
	int lo[3] = {0, is_outline ? 1 : 1, 0};
	(void)lo;
	int smin = (d == 1) ? 1 : 0;
	int smax = (d == 1) ? NSLAB : dims[d]-1;
	for (int s = smin; s <= smax; s++) {
		memset(mask, 0, sizeof(int)*nu*nv);
		for (int iu = 0; iu < nu; iu++) {
			for (int iv = 0; iv < nv; iv++) {
				int c[3]; c[d] = s; c[a] = iu; c[b] = iv;
				size_t gi = (size_t)c[0]*stride[0] + (size_t)c[1]*stride[1] + (size_t)c[2]*stride[2];
				int col = is_outline ? O[gi] : G[gi];
				if (col <= 0) continue;
				int c2[3] = {c[0], c[1], c[2]}; c2[d] = s+1;
				if (c2[d] >= dims[d]) continue;
				size_t gj = (size_t)c2[0]*stride[0] + (size_t)c2[1]*stride[1] + (size_t)c2[2]*stride[2];
				int nb = is_outline ? O[gj] : G[gj];
				if (nb > 0) continue;
				mask[iu*nv + iv] = col * 2 + 1;      // +方向
			}
		}
		// 负方向
		for (int iu = 0; iu < nu; iu++) for (int iv = 0; iv < nv; iv++) {
			int c[3]; c[d] = s; c[a] = iu; c[b] = iv;
			size_t gi = (size_t)c[0]*stride[0] + (size_t)c[1]*stride[1] + (size_t)c[2]*stride[2];
			int col = is_outline ? O[gi] : G[gi];
			if (col <= 0) continue;
			int c0[3] = {c[0], c[1], c[2]}; c0[d] = s-1;
			int nb = 0;
			if (c0[d] >= 0) {
				size_t gk = (size_t)c0[0]*stride[0] + (size_t)c0[1]*stride[1] + (size_t)c0[2]*stride[2];
				nb = is_outline ? O[gk] : G[gk];
			}
			if (nb > 0) continue;
			mask[iu*nv + iv] = col * 2 + 0;
		}
		// 矩形合并
		for (int iu = 0; iu < nu; iu++) for (int iv = 0; iv < nv; iv++) {
			int v = mask[iu*nv + iv];
			if (!v) continue;
			int w = 1; while (iu + w < nu && mask[(iu+w)*nv + iv] == v) w++;
			int h = 1; int ok = 1;
			while (iv + h < nv && ok) {
				for (int k = 0; k < w; k++) if (mask[(iu+k)*nv + iv+h] != v) { ok = 0; break; }
				if (ok) h++;
			}
			for (int k = 0; k < w; k++) for (int m2 = 0; m2 < h; m2++) mask[(iu+k)*nv + iv+m2] = 0;
			int col = v >> 1, sgn = v & 1;
			// 计算角点
			float pos[3]; int c3[3]; c3[d] = s + (sgn ? 1 : 0); c3[a] = 0; c3[b] = 0;
			pos[0] = OX + c3[0]*VS; pos[1] = ybase + (c3[1]-1)*VS; pos[2] = OZ + c3[2]*VS;
			float e[3][3] = {{1,0,0},{0,1,0},{0,0,1}};
			int ua = sgn ? a : b, va = sgn ? b : a;
			int uu = sgn ? iu : iv, vv = sgn ? iv : iu, uw = sgn ? w : h, vh = sgn ? h : w;
			float bx = pos[0] + e[ua][0]*uu*VS + e[va][0]*vv*VS;
			float by = pos[1] + e[ua][1]*uu*VS + e[va][1]*vv*VS;
			float bz = pos[2] + e[ua][2]*uu*VS + e[va][2]*vv*VS;
			float nx = sgn ? e[d][0] : -e[d][0];
			float ny = sgn ? e[d][1] : -e[d][1];
			float nz = sgn ? e[d][2] : -e[d][2];
			m_quad(is_outline ? &OUT : &M, bx, by, bz,
				e[ua][0], e[ua][1], e[ua][2], e[va][0], e[va][1], e[va][2],
				uw*VS, vh*VS, nx, ny, nz, is_outline ? 18 : col);
		}
	}
	free(mask);
}

int main(void) {
	G = calloc((size_t)NX*NZ*NYH, 1);
	O = calloc((size_t)NX*NZ*NYH, 1);
	if (!G || !O) { fprintf(stderr, "oom\n"); return 1; }
	int nslab = (int)ceilf(1.90f / (NSLAB * VS));
	for (int s = 0; s < nslab; s++) {
		ybase = s * NSLAB * VS;
		memset(G, 0, (size_t)NX*NZ*NYH);
		build_scene();
		for (int d = 0; d < 3; d++) greedy(d, 0);
		fprintf(stderr, "\rslab %d/%d  v=%zu i=%zu", s+1, nslab, M.vc, M.ic);
	}
	fprintf(stderr, "\n");

	FILE *f = fopen("/root/game/out/voxmesh.bin", "wb");
	if (!f) { perror("fopen"); return 1; }
	fwrite("VX1\0", 1, 4, f);
	uint32_t nm = 1; fwrite(&nm, 4, 1, f);
	for (int k = 0; k < 1; k++) {
		Mesh *m = &M;
		uint32_t vc = (uint32_t)m->vc, ic = (uint32_t)m->ic;
		fwrite(&vc, 4, 1, f); fwrite(&ic, 4, 1, f);
		fwrite(m->p, sizeof(float), m->vc*3, f);
		fwrite(m->n, sizeof(float), m->vc*3, f);
		fwrite(m->c, sizeof(float), m->vc*3, f);
		fwrite(m->idx, sizeof(uint32_t), m->ic, f);
	}
	fclose(f);
	printf("verts=%zu idx=%zu tris=%zu | outline verts=%zu\n", M.vc, M.ic, M.ic/3, OUT.vc);
	return 0;
}
