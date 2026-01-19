class BezierSegment {
    Vector2d p0, p1, p2, p3;
    double maxVel, maxAccel;
    bool reversed = false;

    BezierSegment(this.p0, this.p1, this.p2, this.p3, this.maxVel, this.maxAccel, {this.reversed = false});


    Vector3d poseAtT(double t) const {
        double u = 1.0 - t;
        double tt = t * t;
        double uu = u * u;
        double uuu = uu * u;
        double ttt = tt * t;

        double x = uuu * p0.x() + 3 * uu * t * p1.x() + 3 * u * tt * p2.x() + ttt * p3.x();
        double y = uuu * p0.y() + 3 * uu * t * p1.y() + 3 * u * tt * p2.y() + ttt * p3.y();

        double dx = 3 * uu * (p1.x() - p0.x()) + 6 * u * t * (p2.x() - p1.x()) + 3 * tt * (p3.x() - p2.x());
        double dy = 3 * uu * (p1.y() - p0.y()) + 6 * u * t * (p2.y() - p1.y()) + 3 * tt * (p3.y() - p2.y());
        double theta = atan2(dy, dx);

        return Vector3d(x, y, theta);
    }

    Vector2d derivative(double t) const {
        double u = 1.0 - t;
        double tt = t * t;
        double uu = u * u;

        double dx = 3 * uu * (p1.x() - p0.x()) + 6 * u * t * (p2.x() - p1.x()) + 3 * tt * (p3.x() - p2.x());
        double dy = 3 * uu * (p1.y() - p0.y()) + 6 * u * t * (p2.y() - p1.y()) + 3 * tt * (p3.y() - p2.y());
        return Vector2d(dx, dy);
    }

    Vector2d secondDerivative(double t) const {
        double u = 1.0 - t;
        double tt = t * t;

        double dx = 6 * u * (p2.x() - 2 * p1.x() + p0.x()) + 6 * tt * (p3.x() - 2 * p2.x() + p1.x());
        double dy = 6 * u * (p2.y() - 2 * p1.y() + p0.y()) + 6 * tt * (p3.y() - 2 * p2.y() + p1.y());
        return Vector2d(dx, dy);
    }

    double curvature(double t) const {
        auto v1 = derivative(t);
        auto v2 = secondDerivative(t);
        double num = abs(v1.x() * v2.y() - v1.y() * v2.x());
        double den = pow(v1.squaredNorm(), 1.5);
        return den > 1e-6 ? num / den : 0.0;
    }

    double totalArcLength() const {
        return arcLengthAtT(1.0);
    }

    double arcLengthAtT(double t) const {
        const int samplingRate = 50;
        double length = 0.0;
        double prevX = p0.x(), prevY = p0.y();
        
        for (int i = 1; i <= samplingRate; ++i) {
            double u = t * i / samplingRate;
            Vector3d pos = poseAtT(u);
            length += hypot(pos.x() - prevX, pos.y() - prevY);
            prevX = pos.x(); prevY = pos.y();
        }
        return length;
    }
};