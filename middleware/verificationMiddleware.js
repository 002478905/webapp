// middleware/verificationMiddleware.js

const checkEmailVerification = async (req, res, next) => {
  try {
    const user = req.user; // User is already attached from auth middleware

    if (!user.emailVerified) {
      return res.status(403).json({ message: "Email not verified" });
    }

    next();
  } catch (error) {
    console.error("Verification check error:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
};

module.exports = checkEmailVerification;
