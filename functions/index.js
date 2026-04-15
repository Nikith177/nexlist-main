const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

const SITE_URL = "https://www.nexlist.in";
const DEFAULT_IMAGE_URL = `${SITE_URL}/icons/Icon-512.png`;
const GENERIC_TITLE = "Nexlist – Campus Marketplace";
const GENERIC_DESCRIPTION =
  "Campus marketplace for students to buy, sell, rent items and services.";

exports.listingPreview = onRequest(async (req, res) => {
  const listingId = extractListingId(req.path);
  const redirectUrl = listingId ?
    `${SITE_URL}/listing/${encodeURIComponent(listingId)}` :
    SITE_URL;

  let title = GENERIC_TITLE;
  let description = GENERIC_DESCRIPTION;
  let imageUrl = DEFAULT_IMAGE_URL;

  if (listingId) {
    try {
      const snapshot = await getFirestore()
        .collection("listings")
        .doc(listingId)
        .get();

      if (snapshot.exists) {
        const data = snapshot.data() || {};
        const listingTitle = cleanText(data.title) || "Listing on Nexlist";
        const location = resolveLocation(data);
        const firstImage = resolvePublicImageUrl(resolveImages(data)[0]);
        const price = parsePrice(data.price);
        const isFree = resolveType(data) === "sell" && price === 0;

        title = isFree ? "🎁 FREE on Nexlist" : `${listingTitle} | Nexlist`;

        if (isFree) {
          description = joinParts([listingTitle, location]) || listingTitle;
        } else {
          const priceText = price != null && price > 0 ?
            `₹${formatAmount(price)}` :
            "";
          description =
            joinParts([priceText, location]) || listingTitle || GENERIC_DESCRIPTION;
        }

        if (firstImage) {
          imageUrl = firstImage;
        }
      }
    } catch (error) {
      console.error("listingPreview fetch failed", error);
    }
  }

  res
    .status(200)
    .set("Content-Type", "text/html; charset=utf-8")
    .send(renderHtml({
      title,
      description,
      imageUrl,
      redirectUrl,
    }));
});

function extractListingId(pathname) {
  const match = pathname.match(/^\/preview\/listing\/([^/]+)\/?$/);
  return match ? decodeURIComponent(match[1]) : "";
}

function resolveType(data) {
  return cleanText(data.type || data.listing_type || "") || "";
}

function resolveLocation(data) {
  const locationType = cleanText(data.location_type)?.toLowerCase();

  switch (locationType) {
    case "hostel":
      return cleanText(data.location_tag) || "";
    case "campus":
      return cleanText(data.location_detail) || "";
    case "anywhere":
      return "Anywhere";
    case "online":
      return "Online";
    default:
      return "";
  }
}

function resolveImages(data) {
  const rawImages = data.imageUrls || data.image_urls;
  if (Array.isArray(rawImages)) {
    const urls = rawImages
      .map((value) => cleanText(value))
      .filter((value) => value && value !== "placeholder");
    if (urls.length > 0) {
      return urls;
    }
  }

  const singleImage = cleanText(data.imageUrl || data.image_url);
  return singleImage ? [singleImage] : [];
}

function resolvePublicImageUrl(imageUrl) {
  return imageUrl && imageUrl.startsWith("https://") ?
    imageUrl :
    DEFAULT_IMAGE_URL;
}

function parsePrice(rawPrice) {
  if (typeof rawPrice === "number" && Number.isFinite(rawPrice)) {
    return rawPrice;
  }

  if (typeof rawPrice === "string") {
    const parsed = Number(rawPrice.trim());
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
}

function formatAmount(amount) {
  return Number.isInteger(amount) ?
    amount.toString() :
    amount.toFixed(2).replace(/\.?0+$/, "");
}

function joinParts(parts) {
  return parts.map((part) => part.trim()).filter(Boolean).join(" • ");
}

function cleanText(value) {
  if (value == null) {
    return "";
  }

  const text = String(value).trim();
  if (!text) {
    return "";
  }

  const normalized = text.toLowerCase();
  if (["unknown", "null", "undefined", "n/a"].includes(normalized)) {
    return "";
  }

  return text;
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function renderHtml({title, description, imageUrl, redirectUrl}) {
  const escapedTitle = escapeHtml(title);
  const escapedDescription = escapeHtml(description);
  const escapedImageUrl = escapeHtml(imageUrl);
  const escapedRedirectUrl = escapeHtml(redirectUrl);
  const redirectUrlJson = JSON.stringify(redirectUrl);

  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>${escapedTitle}</title>
    <meta name="description" content="${escapedDescription}">
    <meta property="og:title" content="${escapedTitle}">
    <meta property="og:description" content="${escapedDescription}">
    <meta property="og:image" content="${escapedImageUrl}">
    <meta property="og:url" content="${escapedRedirectUrl}">
    <meta property="og:type" content="website">
    <meta http-equiv="refresh" content="1; url=${escapedRedirectUrl}">
  </head>
  <body>
    <div style="text-align:center; margin-top:40vh; font-family:sans-serif;">
      <h3>Opening listing...</h3>
    </div>
    <script>
      setTimeout(function() {
        window.location.replace(${redirectUrlJson});
      }, 500);
    </script>
  </body>
</html>`;
}
