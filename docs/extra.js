// Lightbox modal for the entity relationship diagram
document.addEventListener("DOMContentLoaded", function () {
  var img = document.querySelector(
    'img[alt="SELMA entity relationship diagram"]'
  );
  if (!img) return;

  // Wrap image in a clickable container
  var container = document.createElement("div");
  container.className = "diagram-container";
  img.parentNode.insertBefore(container, img);
  container.appendChild(img);

  // Create modal
  var modal = document.createElement("div");
  modal.className = "diagram-modal";
  modal.innerHTML =
    '<button class="diagram-modal-close">Close &times;</button>' +
    '<img src="' + img.src + '" alt="SELMA entity relationship diagram">';
  document.body.appendChild(modal);

  // Open on click
  container.addEventListener("click", function () {
    modal.classList.add("active");
  });

  // Close on button click
  modal.querySelector(".diagram-modal-close").addEventListener("click", function (e) {
    e.stopPropagation();
    modal.classList.remove("active");
  });

  // Close on backdrop click
  modal.addEventListener("click", function (e) {
    if (e.target === modal) {
      modal.classList.remove("active");
    }
  });

  // Close on Escape key
  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape") {
      modal.classList.remove("active");
    }
  });
});
