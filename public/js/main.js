const categories = document.querySelectorAll('.categories div');
const colors = document.querySelectorAll('.categories div span');
const tags = document.querySelectorAll('.tags ul li');
const cloneTags = document.querySelector('select[name="tag"]');
const addTagsButton = document.querySelector('#add-tags');
const signupSubmitButton = document.querySelector('#signup form button');
const signupButton = document.querySelector('#signup-button');
const categoryDropdown = document.querySelectorAll(".category");
const colorMode = document.querySelector('#color-mode');
const profileButton = document.querySelector('#profile-button');
const settingsButton = document.querySelector('#settings-button');
let styleSheet = document.querySelector('#styleSheet');

function loadNotification(notificationMessage){
   const notificationBar = document.createElement('div');
   const message = document.createElement('p');
   const messageText = document.createTextNode(notificationMessage);
   notificationBar.setAttribute('id', 'notification');
   message.appendChild(messageText);
   notificationBar.appendChild(message);
   document.querySelector('body').appendChild(notificationBar);
}

function checkPasswords(password, confirmPassword) {
   const message = 'Passwords dont match'; 
   if(password !== confirmPassword){
       loadNotification(message);
       document.querySelector('#signup form').reset();
   } else {
       getSignupFormData();
   }
}

function getSignupFormData(){
    const fullname = document.querySelector('#fullname').value 
    const username = document.querySelector('#username').value;   
    const email = document.querySelector("#email").value;
    const password = document.querySelector('#password').value;
    let jsonData = JSON.stringify({
        fullname : fullname,
        username : username,
        email : email,
        password : password
     })

    fetch('http://localhost:4567/signup', {
        method: 'POST',
        headers: {'Content-Type' : 'application/json'},
        body: jsonData
    })
    .then(response => response.json())
    .then(data => checkAccountStatus(data))
    .catch(err => console.log(err))
    document.querySelector('#signup form').reset();
}

function checkAccountStatus(data){
    if(data['status'] == 200) {
       window.location.href='/add/profile'; 
    } else {
       window.location.href='/signup'; 
    }
} 

function createLink(elementClassName){
    const link = document.createElement('a');
    const linkText = document.createTextNode('\u205D more');
    link.setAttribute('class', 'readmore');
    link.setAttribute('href', '');
    link.appendChild(linkText);
    document.querySelector(elementClassName).appendChild(link);
}

function reduceMenuItems(menuItems){
    let itemArray = [];
    menuItems.forEach((item, index) => {
         if(index > 4) {
            if(menuItem == '.categories'){
                itemArray.push({category: item.getAttribute('data-category'), colors: colors[index].getAttribute('data-colors') });
                item.remove();
                colors[index].remove();
            } else {
                itemArray.push({tag: tag.getAttribute('data-tag')});
                item.remove();
            }
         }
    })
}

function addToForm(item){
    document.querySelector('#forum form').appendChild(item);
    const textarea = document.querySelector('#forum form textarea');
    const parentForm = textarea.parentNode;
    parentForm.insertBefore(item, textarea);
    addTagsButton.disabled=true;
}

function createClone(item){
    const clone = item.cloneNode(true);
    clone.setAttribute('name', 'tag2');
    addToForm(clone);
}

function toggleStylesheet(theme) {
    let mode = styleSheet.getAttribute('href').split('/')[2].split('.')[0]
    if(mode == 'dark'){
         localStorage.setItem('theme', '/css/light.mode.css');
         let lightMode = localStorage.getItem('theme');
         styleSheet.setAttribute('href', lightMode);
         colorMode.innerHTML='<i class="fa-solid fa-moon"></i>';

    } else {
         localStorage.setItem('theme', '/css/dark.mode.css');
         let darkMode = localStorage.getItem('theme');
         styleSheet.setAttribute('href', darkMode);
         colorMode.innerHTML='<i class="fa-solid fa-sun"></i>';
         
    }
}

function loadStylesheet(){
    currentStylesheet = localStorage.getItem('theme') || '/css/light.mode.css';
    styleSheet.setAttribute('href', currentStylesheet);
    document.querySelector('body').style.display='block';
}

window.addEventListener('load', (e) => {
    e.preventDefault();
    loadStylesheet();
    if(colorMode){
        colorMode.addEventListener('click', (e) => {
            e.preventDefault();
            toggleStylesheet(localStorage.getItem('theme') || '/css/light.mode.css');
        })
   } 

   /*
   profileButton.addEventListener('click', (e) => {
      e.preventDefault();
      document.querySelector('#settings').style.display='none';
      document.querySelector('#profile-body').style.display='block';
   })
   

    settingsButton.addEventListener('click', (e) => {
        e.preventDefault();
        document.querySelector('#profile-body').style.display='none';
        document.querySelector('#settings').style.display='block';
    })
*/


}) 

window.addEventListener('DOMContentLoaded', (e) => {
  if(addTagsButton){
      addTagsButton.addEventListener('click', (e) => {
         e.preventDefault();
         createClone(cloneTags);
      })
  }   

  if(signupSubmitButton){
        signupSubmitButton.addEventListener('click', (e) => {
            e.preventDefault();
            let passwordField = document.querySelector('#password').value;
            let confirmPassword = document.querySelector('#confirm-password').value;
            checkPasswords(passwordField, confirmPassword);
       })
   } 


   if(signupButton){
     signupButton.addEventListener('click', (e) => {
        e.preventDefault();
        window.location.href='/signup'; 
     })
   }
 
})

