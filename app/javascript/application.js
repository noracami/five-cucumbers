// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

addEventListener("turbo:before-stream-render", (event) => {
  if (document.startViewTransition) {
    const originalRender = event.detail.render;
    event.detail.render = (currentElement, newElement) => {
      document.startViewTransition(() => {
        originalRender(currentElement, newElement);
        setTimeout(() => {
          document.querySelector(".chat")?.classList?.remove("chat");
          document
            .querySelector(".played-card")
            ?.classList?.remove("played-card");
        }, 0);
      });
    };
  }
});
