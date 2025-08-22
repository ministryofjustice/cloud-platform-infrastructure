// nav.js - Dynamically injects the navigation bar into the page
function renderNavbar() {
  var navHtml = `
  <nav class="navbar navbar-default">
    <div class="container-fluid">
      <div class="navbar-header">
        <a class="navbar-brand" href="/">Policy Usage</a>
      </div>
      <ul class="nav navbar-nav">
        <li><a href="#">About</a></li>
        <li><a href="#">Contact</a></li>
      </ul>
    </div>
  </nav>
  `;
  var navDiv = document.getElementById('navbar');
  if (navDiv) {
    navDiv.innerHTML = navHtml;
  }
}
