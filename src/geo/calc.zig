const std = @import("std");
const rl = @import("raylib");

/// Represents a 2D line segment with additional operations for transformations and rendering.
///
/// Methods:
/// - init
/// - drawCircleSector
/// - drawText
/// - drawLine
/// - scale
/// - rotateEndVector
/// - endAtIntersection
/// - startAtIntersection
pub const Line = struct {
    start: rl.Vector2,
    end: rl.Vector2,
    angle: f32,

    pub fn init(start: rl.Vector2, end: rl.Vector2, rotate: bool, angle: f32) !Line {
        return Line{
            .start = start,
            .end = if (rotate) try rotateEndVector(start, end, angle) else end,
            .angle = angle,
        };
    }

    pub fn drawCircleSector(self: *Line, radius: f32) void {
        rl.drawRingLines(
            .{ .x = self.start.x, .y = self.start.y },
            radius,
            radius,
            -90,
            -90 + milsToDegree(self.angle),
            50,
            rl.Color.maroon,
        );
    }

    pub fn drawText(self: *Line, text: [*:0]const u8, textOffsetX: i32, textOffsetY: i32, fontSize: i32) void {
        rl.drawText(
            text,
            @as(i32, @intFromFloat(self.end.x)) + textOffsetX,
            @as(i32, @intFromFloat(self.end.y)) + textOffsetY,
            fontSize,
            rl.Color.black,
        );
    }

    pub fn drawLine(self: *Line) void {
        rl.drawLine(
            @as(i32, @intFromFloat(self.start.x)),
            @as(i32, @intFromFloat(self.start.y)),
            @as(i32, @intFromFloat(self.end.x)),
            @as(i32, @intFromFloat(self.end.y)),
            rl.Color.maroon,
        );
    }

    pub fn scale(self: *Line, factor: f32) void {
        self.end.x *= factor;
        self.end.y *= factor;
        self.start.x *= factor;
        self.start.y *= factor;
    }

    pub fn endAtIntersection(self: *Line, line: Line) void {
        self.*.end = getLineIntersectionPoint(self.*, line) orelse rl.Vector2{
            .x = 0,
            .y = 0,
        };
    }

    pub fn startAtIntersection(self: *Line, line: Line) void {
        self.*.start = getLineIntersectionPoint(self.*, line) orelse rl.Vector2{
            .x = 0,
            .y = 0,
        };
    }
};

/// Rotates the endpoint of a `Line` around its starting point by the specified angle.
///
/// This function returns a new rotated Vector2 with the new position of the endpoint.
///
/// The rotation is performed using the formula for rotating points around an arbitrary center.
fn rotateEndVector(start: rl.Vector2, end: rl.Vector2, angle: f32) !rl.Vector2 {
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const rad = milsToRadians(angle);

    const cosAngle = @cos(rad);
    const sinAngle = @sin(rad);

    return rl.Vector2{
        .x = (dx * cosAngle) - (dy * sinAngle) + start.x,
        .y = (dx * sinAngle) + (dy * cosAngle) + start.y,
    };
}
/// Calculates the intersection point of two line segments, if it exists.
///
/// The function determines the point where two lines intersect, based on their
/// start and end coordinates. If the lines are parallel and do not intersect,
/// it returns `null`.
///
/// The formula for finding the intersection is derived from solving the equations
/// of the two lines in parametric form:
fn getLineIntersectionPoint(line1: Line, line2: Line) ?rl.Vector2 {
    // Line 1 points
    const line1_start_x: f32 = line1.start.x;
    const line1_start_y: f32 = line1.start.y;
    const line1_end_x: f32 = line1.end.x;
    const line1_end_y: f32 = line1.end.y;

    // Line 2 points
    const line2_start_x: f32 = line2.start.x;
    const line2_start_y: f32 = line2.start.y;
    const line2_end_x: f32 = line2.end.x;
    const line2_end_y: f32 = line2.end.y;

    // Denominator for the intersection calculation
    const denominator = (line1_start_x - line1_end_x) * (line2_start_y - line2_end_y) - (line1_start_y - line1_end_y) * (line2_start_x - line2_end_x);
    if (denominator == 0) return null;

    // Parameter t for intersection calculation
    const t = ((line1_start_x - line2_start_x) * (line2_start_y - line2_end_y) - (line1_start_y - line2_start_y) * (line2_start_x - line2_end_x)) / denominator;

    // Intersection point
    const intersection_x = line1_start_x + t * (line1_end_x - line1_start_x);
    const intersection_y = line1_start_y + t * (line1_end_y - line1_start_y);

    return rl.Vector2{ .x = intersection_x, .y = intersection_y };
}

/// Calculates a line parallel to the given line at a specified distance.
///
/// This function computes the coordinates of a line parallel to the input line.
/// The parallel line is offset by a specified distance `c` along a perpendicular
/// direction.
///
/// The perpendicular direction is calculated by rotating the original direction vector
/// of the line by 90 degrees, then normalizing it. The endpoints of the original line
/// are then offset by the perpendicular vector scaled by the distance `c`.
pub fn getParallelLine(line: Line, c: f32) !Line {
    const start_x: f32 = line.start.x;
    const start_y: f32 = line.start.y;
    const end_x: f32 = line.end.x;
    const end_y: f32 = line.end.y;

    // Compute direction vector of the original line
    const dx = end_x - start_x;
    const dy = end_y - start_y;

    // Compute the perpendicular direction (90 degrees rotated)
    var perpendicular_x = -dy;
    var perpendicular_y = dx;

    // Normalize the perpendicular direction
    const length = std.math.sqrt(perpendicular_x * perpendicular_x + perpendicular_y * perpendicular_y);
    perpendicular_x /= length;
    perpendicular_y /= length;

    // Offset the original line by distance c along the perpendicular direction
    const offset_x = perpendicular_x * c;
    const offset_y = perpendicular_y * c;

    // Calculate new endpoints for the parallel line (both above and below the original line)
    const x1_parallel = start_x + offset_x;
    const y1_parallel = start_y + offset_y;
    const x2_parallel = end_x + offset_x;
    const y2_parallel = end_y + offset_y;

    // Return the new start and end points of the parallel line
    return Line{ .start = rl.Vector2{ .x = x1_parallel, .y = y1_parallel }, .end = rl.Vector2{ .x = x2_parallel, .y = y2_parallel }, .angle = undefined };
}

/// Converts a given angle in mils to degrees.
fn milsToDegree(mils: f32) f32 {
    return mils * 0.05625;
}

/// Converts a given angle in mils to radians.
fn milsToRadians(mils: f32) f32 {
    return mils * 0.000982;
}

/// Calculates the length of one leg of a right triangle given the other leg and an angle.
pub fn calculateXfromAngle(width: i32, angle: f32) f32 {
    const b: f32 = @as(f32, @floatFromInt(width));
    const a: f32 = @tan(milsToRadians(angle));

    return (b * a);
}
