const categories = document.querySelectorAll('.categories div');
const colors = document.querySelectorAll('.categories div span');
const tags = document.querySelectorAll('.tags ul li');
const cloneTags = document.querySelector('select[name="tag"]');
const addTagsButton = document.querySelector('#add-tags');
const forumSubmitButton = document.querySelector('#signup form button');
const categoryDropdown = document.querySelectorAll(".category");

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
    .catch(err => console.log(err))
    document.querySelector('#signup form').reset();
    window.location.href='/add/profile';
     
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

window.addEventListener('DOMContentLoaded', (e) => {
  if(addTagsButton){
      addTagsButton.addEventListener('click', (e) => {
         e.preventDefault();
         createClone(cloneTags);
      })
  }   

   if(forumSubmitButton){
        forumSubmitButton.addEventListener('click', (e) => {
            e.preventDefault();
            let passwordField = document.querySelector('#password').value;
            let confirmPassword = document.querySelector('#confirm-password').value;
            checkPasswords(passwordField, confirmPassword);
       })
   }
})




