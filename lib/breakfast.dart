#breakfirst_2
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
<meta charset="UTF-8">
<title>早餐紀錄 APP</title>
<style>
    body {
        font-family: Arial;
        display: flex;
        margin: 0;
        background: #f5f5f5;
    }
    #sidebar {
        width: 220px;
        background: #ddd;
        height: 100vh;
        padding-top: 20px;
    }
    #sidebar div {
        padding: 12px;
        cursor: pointer;
    }
    #sidebar div.active {
        background: #aaa;
        font-weight: bold;
    }

    #main {
        flex: 1;
        padding: 20px;
    }

    .row {
        background: white;
        padding: 10px;
        border-radius: 6px;
        margin-bottom: 12px;
        box-shadow: 0 0 3px #ccc;
    }

    .preview {
        width: 60px;
        height: 60px;
        object-fit: cover;
        border-radius: 6px;
    }

    .member-box {
        display: inline-flex;
        align-items: center;
        border: 2px solid #ccc;
        padding: 5px 10px;
        border-radius: 6px;
        margin: 5px;
        font-size: 18px;
    }

    .heart {
        font-size: 26px;
        cursor: pointer;
        color: black;
        margin-right: 10px;
    }
    .heart.fav {
        color: red;
    }

    .modal {
        position: fixed;
        top: 0; left: 0; right: 0; bottom: 0;
        display: none;
        background: rgba(0,0,0,0.5);
        justify-content: center;
        align-items: center;
    }
    .modal-content {
        background: white;
        padding: 20px;
        width: 420px;
        border-radius: 10px;
        max-height: 80vh;
        overflow-y: auto;
    }

    .grid-item {
        padding: 10px;
        border: 1px solid #ccc;
        cursor: pointer;
        margin: 3px;
        text-align: center;
        border-radius: 6px;
    }
    .grid-item.selected {
        border: 3px solid black;
    }

    .member-grid {
        display: flex;
        flex-wrap: wrap;
    }

</style>
</head>
<body>

<div id="sidebar">
    <div class="active" onclick="switchPage('home')">用餐資訊記錄頁面</div>
    <div onclick="switchPage('history')">歷史紀錄</div>
    <div onclick="switchPage('favStores')">喜歡的店家</div>
    <div onclick="switchPage('favDishes')">喜歡的餐點</div>
    <div onclick="switchPage('team')">設計團隊</div>
</div>

<div id="main">

<!-- ======================= 頁面：首頁 ======================= -->
<div id="page-home">

    <h2>用餐日期</h2>
    <div class="row">
        <select id="year"></select>
        <select id="month"></select>
        <select id="day"></select>
        <select id="hour"></select>
        <select id="minute"></select>
    </div>

    <div class="row">
        <button onclick="openStoreForm()">輸入早餐店資訊</button>

        <div style="display:flex; margin-top:10px;">
            <div id="storeFav" class="heart" onclick="toggleStoreFav()">★</div>
            <img id="storeImg" class="preview" src="">
            <div id="storeName" style="margin-left:10px;">尚未輸入</div>
        </div>
    </div>

    <div class="row">
        <strong>店家地址</strong>
        <button onclick="jumpMap()">跳轉到 Google Map</button>
        <span id="mapStatus" style="color:gray;">●</span>
        <input id="addressInput" oninput="detectMap()"
               placeholder="此處可以輸入店家地址或 google map 連結"
               style="width:100%; margin-top:10px;">
    </div>

    <div class="row">
        <button onclick="openMemberForm()">+ 添加參與成員</button>
        <div id="memberList" style="margin-top:10px;"></div>
    </div>

    <div class="row">
        <button onclick="openDishForm()">新增餐點</button>
        <div id="dishList" style="margin-top:10px;"></div>
    </div>

    <div class="row">
        <h3>總價：<span id="totalPrice">0</span></h3>
        <div id="costList" style="margin-top:10px;"></div>

        <button onclick="finishAndReset()"
                style="margin-top:20px;">儲存此次用餐紀錄</button>
    </div>

</div>

<!-- ======================= 頁面：歷史紀錄 ======================= -->
<div id="page-history" style="display:none;">
    <h2>歷史紀錄</h2>
    <div id="historyList"></div>
</div>

<!-- ======================= 頁面：喜歡的店家 ======================= -->
<div id="page-favStores" style="display:none;">
    <h2>喜歡的店家</h2>
    <div id="favStoreList"></div>
</div>

<!-- ======================= 頁面：喜歡的餐點 ======================= -->
<div id="page-favDishes" style="display:none;">
    <h2>喜歡的餐點</h2>
    <div id="favDishList"></div>
</div>

<!-- ======================= 頁面：設計團隊 ======================= -->
<div id="page-team" style="display:none;">
    <h2>設計團隊</h2>
    <p>小狗寶貝 & 小雀 (ChatGPT)</p>

    <p>參與成員：簡幼承、陳歆棠、許方瑜</p>

    <p>2025 © Breakfast Recorder</p>
</div>


<!-- ======================= 店家資訊 FORM ======================= -->
<div class="modal" id="storeModal">
    <div class="modal-content">
        <h3>早餐店資訊</h3>

        <input type="file" id="storeImgInput" accept="image/*"><br><br>

        <input type="text" id="storeNameInput"
               placeholder="早餐店名稱"
               style="width:100%; padding:6px;">

        <br><br>
        <button onclick="saveStore()">確認</button>
        <button onclick="closeStoreForm()">取消</button>
    </div>
</div>


<!-- ======================= 成員資訊 FORM ======================= -->
<div class="modal" id="memberModal">
    <div class="modal-content">
        <h3>新增 / 編輯 成員</h3>

        <input type="file" id="memberImgInput" accept="image/*"><br><br>

        <h4>預設角色圖示</h4>
        <div class="member-grid" id="defaultIcons">
            <div class="grid-item">🐶</div>
            <div class="grid-item">🐱</div>
            <div class="grid-item">🐰</div>
            <div class="grid-item">🐵</div>
            <div class="grid-item">🐸</div>
            <div class="grid-item">🐼</div>
        </div>

        <h4>角色框線顏色</h4>
        <div class="member-grid" id="colorPick">
            <div class="grid-item" style="background:red"></div>
            <div class="grid-item" style="background:orange"></div>
            <div class="grid-item" style="background:yellow"></div>
            <div class="grid-item" style="background:green"></div>
            <div class="grid-item" style="background:blue"></div>
            <div class="grid-item" style="background:purple"></div>
            <div class="grid-item" style="background:black"></div>
            <div class="grid-item" style="background:white"></div>
            <div class="grid-item" style="background:gray"></div>
        </div>

        <br>

        <input type="text" id="memberNameInput"
               placeholder="請輸入成員姓名"
               style="width:100%; padding:6px;">

        <br><br>

        <button onclick="saveMember()">輸入完成</button>
        <button onclick="closeMemberForm()">取消</button>
    </div>
</div>


<!-- ======================= 餐點 FORM ======================= -->
<div class="modal" id="dishModal">
    <div class="modal-content">
        <h3>新增餐點</h3>

        <input type="file" id="dishImgInput" accept="image/*"><br><br>

        <input type="text" id="dishNameInput"
               placeholder="請在此處輸入餐點名稱"
               style="width:100%; padding:6px;"><br><br>

        <input type="number" step="0.1" id="dishPriceInput"
               placeholder="請輸入餐點金額"
               style="width:100%; padding:6px;"><br><br>

        <h4>選擇點餐成員</h4>
        <div id="dishMemberCandidates"></div>

        <h4>已選成員</h4>
        <div id="dishMemberSelected"></div>

        <br>
        <button onclick="saveDish()">輸入資訊完成</button>
        <button onclick="closeDishForm()">取消</button>
    </div>
</div>
<script>
    // ============================
    //  日期下拉式選單自動生成
    // ============================
    (function initDateSelectors() {
        let y = new Date().getFullYear();
        for (let i = y - 3; i <= y + 1; i++) {
            year.insertAdjacentHTML("beforeend", `<option value="${i}">${i}</option>`);
        }
        for (let i = 1; i <= 12; i++) {
            month.insertAdjacentHTML("beforeend", `<option value="${i}">${i}</option>`);
        }
        for (let i = 1; i <= 31; i++) {
            day.insertAdjacentHTML("beforeend", `<option value="${i}">${i}</option>`);
        }
        for (let i = 0; i <= 23; i++) {
            hour.insertAdjacentHTML("beforeend", `<option value="${i}">${i}</option>`);
        }
        for (let i = 0; i <= 59; i++) {
            minute.insertAdjacentHTML("beforeend", `<option value="${i}">${i}</option>`);
        }
    })();
    
    // ============================
    //  全域資料
    // ============================
    let storeData = { name:"", img:"", fav:false, address:"" };
    let members = []; 
    let dishes = [];
    let history = [];
    
    let editMemberId = null;
    let selectedIcon = null;
    let selectedColor = null;
    let selectedDishMembers = [];
    
    
    // ============================
    //  頁面切換
    // ============================
    function switchPage(p) {
        document.querySelectorAll("#sidebar div").forEach(d => d.classList.remove("active"));
        event.target.classList.add("active");
    
        document.querySelectorAll("#main > div").forEach(pg => pg.style.display = "none");
        document.querySelector("#page-" + p).style.display = "block";
    
        if (p === "history") renderHistory();
        if (p === "favStores") renderFavStores();
        if (p === "favDishes") renderFavDishes();
    }
    
    
    // ============================
    //  店家表單
    // ============================
    function openStoreForm() {
        storeModal.style.display = "flex";
    }
    function closeStoreForm() {
        storeModal.style.display = "none";
    }
    
    function saveStore() {
        let f = storeImgInput.files[0];
        if (f) {
            let r = new FileReader();
            r.onload = () => {
                storeData.img = r.result;
                storeImg.src = r.result;
            };
            r.readAsDataURL(f);
        }
    
        storeData.name = storeNameInput.value || "未命名店家";
        storeName.innerText = storeData.name;
    
        closeStoreForm();
    }
    
    function toggleStoreFav() {
        storeData.fav = !storeData.fav;
        storeFav.classList.toggle("fav", storeData.fav);
    }
    
    
    // ============================
    //  地址偵測
    // ============================
    function detectMap() {
        let addr = addressInput.value;
        storeData.address = addr;
    
        if (!addr) {
            mapStatus.style.color = "gray";
            return;
        }
    
        if (addr.includes("maps.google.com") || addr.includes("goo.gl/maps")) {
            mapStatus.style.color = "green";
        } else {
            mapStatus.style.color = "yellow";
        }
    }
    
    function jumpMap() {
        if (!storeData.address) return alert("尚未輸入地址");
        window.open("https://www.google.com/maps/search/" + encodeURIComponent(storeData.address));
    }
    
    
    // ============================
    //  成員表單
    // ============================
    defaultIcons.querySelectorAll(".grid-item").forEach(item => {
        item.onclick = () => {
            defaultIcons.querySelectorAll(".grid-item").forEach(i => i.classList.remove("selected"));
            item.classList.add("selected");
            selectedIcon = item.innerText;
        };
    });
    
    colorPick.querySelectorAll(".grid-item").forEach(item => {
        item.onclick = () => {
            colorPick.querySelectorAll(".grid-item").forEach(i => i.classList.remove("selected"));
            item.classList.add("selected");
            selectedColor = item.style.background;
        };
    });
    
    function openMemberForm(id = null) {
        editMemberId = id;
        memberModal.style.display = "flex";
    
        // reset selection
        defaultIcons.querySelectorAll(".grid-item").forEach(i => i.classList.remove("selected"));
        colorPick.querySelectorAll(".grid-item").forEach(i => i.classList.remove("selected"));
    
        if (id) {
            let m = members.find(x => x.id === id);
            memberNameInput.value = m.name;
    
            selectedIcon = m.icon;
            selectedColor = m.color;
    
            defaultIcons.querySelectorAll(".grid-item").forEach(i => {
                if (i.innerText === m.icon) i.classList.add("selected");
            });
    
            colorPick.querySelectorAll(".grid-item").forEach(i => {
                if (i.style.background === m.color) i.classList.add("selected");
            });
    
        } else {
            memberNameInput.value = "";
            selectedIcon = null;
            selectedColor = null;
        }
    }
    
    function closeMemberForm() {
        editMemberId = null;
        memberModal.style.display = "none";
    }
    
    function saveMember() {
        let name = memberNameInput.value || "未命名";
        let file = memberImgInput.files[0];
        let imgData = "";
    
        if (file) {
            let r = new FileReader();
            r.onload = () => finalizeMember(r.result);
            r.readAsDataURL(file);
        } else {
            finalizeMember("");
        }
    }
    
    function finalizeMember(img) {
        if (editMemberId) {
            let m = members.find(x => x.id === editMemberId);
            m.name = memberNameInput.value || m.name;
            m.icon = selectedIcon || m.icon;
            m.color = selectedColor || m.color;
            if (img) m.img = img;
        } else {
            members.push({
                id: Date.now(),
                name: memberNameInput.value || "未命名",
                icon: selectedIcon,
                color: selectedColor,
                img
            });
        }
    
        renderMembers();
        closeMemberForm();
    }
    
    function renderMembers() {
        memberList.innerHTML = "";
    
        members.forEach(m => {
            let iconHTML =
                m.img ? `<img src="${m.img}" class="preview">` :
                (m.icon ? m.icon : "🙂");
    
            let div = document.createElement("div");
            div.className = "member-box";
            div.style.borderColor = m.color || "#ccc";
    
            div.innerHTML = `
                <div style="font-size:30px;">${iconHTML}</div>
                <div>${m.name}</div>
            `;
    
            div.onmouseenter = () => showMemberMenu(div, m.id);
            div.onmouseleave = () => {
                let menu = div.querySelector(".menu");
                if (menu) menu.remove();
            };
    
            memberList.appendChild(div);
        });
    }
    
    function showMemberMenu(box, id) {
        let menu = document.createElement("div");
        menu.className = "menu";
        menu.style = `
            position:absolute;
            background:white;
            border:1px solid #aaa;
            padding:5px;
            z-index:10;
        `;
        menu.innerHTML = `
            <div style="cursor:pointer;" onclick="editMember(${id})">編輯成員資訊</div>
            <div style="cursor:pointer;" onclick="deleteMember(${id})">刪除成員</div>
        `;
        box.appendChild(menu);
    }
    
    function editMember(id) {
        openMemberForm(id);
    }
    
    function deleteMember(id) {
        members = members.filter(m => m.id !== id);
        renderMembers();
    }
    
    
    // ============================
    //  餐點表單
    // ============================
    function openDishForm() {
        selectedDishMembers = [];
        dishModal.style.display = "flex";
        renderDishMemberSelect();
    }
    
    function closeDishForm() {
        dishModal.style.display = "none";
    }
    
    function renderDishMemberSelect() {
        dishMemberCandidates.innerHTML = "";
        dishMemberSelected.innerHTML = "";
    
        members.forEach(m => {
            let d = document.createElement("div");
            d.className = "member-box";
            d.style.cursor = "pointer";
            d.innerHTML = `${m.icon || "🙂"} ${m.name}`;
    
            d.onclick = () => {
                if (!selectedDishMembers.includes(m.id)) {
                    selectedDishMembers.push(m.id);
                    renderDishMemberSelect();
                }
            };
            dishMemberCandidates.appendChild(d);
        });
    
        selectedDishMembers.forEach(id => {
            let m = members.find(x => x.id === id);
            let d = document.createElement("div");
            d.className = "member-box";
            d.innerHTML = `${m.icon || "🙂"} ${m.name}`;
            dishMemberSelected.appendChild(d);
        });
    }
    
    function saveDish() {
        let name = dishNameInput.value;
        let price = parseFloat(dishPriceInput.value) || 0;
        let file = dishImgInput.files[0];
        let img = "";
    
        if (file) {
            let r = new FileReader();
            r.onload = () => finalizeDish(r.result);
            r.readAsDataURL(file);
        } else {
            finalizeDish("");
        }
    }
    
    function finalizeDish(img) {
        dishes.push({
            id: Date.now(),
            name: dishNameInput.value || "未命名餐點",
            price: parseFloat(dishPriceInput.value) || 0,
            img,
            fav: false,
            members: [...selectedDishMembers]
        });
    
        renderDishes();
        calculateCost();
        closeDishForm();
    }
    
    
    // ============================
    //  餐點渲染（含刪除）
    // ============================
    function renderDishes() {
        dishList.innerHTML = "";
    
        dishes.forEach(d => {
            let div = document.createElement("div");
            div.className = "dish-box row";
    
            // 喜歡按鈕
            let heart = document.createElement("div");
            heart.className = "heart";
            if (d.fav) heart.classList.add("fav");
            heart.innerHTML = "❤";
            heart.onclick = () => {
                d.fav = !d.fav;
                heart.classList.toggle("fav");
            };
    
            // 刪除按鈕
            let del = document.createElement("button");
            del.innerText = "刪除";
            del.style.marginLeft = "10px";
            del.onclick = () => {
                dishes = dishes.filter(x => x.id !== d.id);
                renderDishes();
                calculateCost();
            };
    
            let top = document.createElement("div");
            top.style.display = "flex";
            top.style.alignItems = "center";
    
            top.appendChild(heart);
    
            top.insertAdjacentHTML("beforeend", `
                <img src="${d.img}" class="preview">
                <div style="margin-left:10px;">
                    <div>${d.name}</div>
                    <div>$${d.price}</div>
                </div>
            `);
    
            top.appendChild(del);
    
            div.appendChild(top);
    
            // 成員列
            let memberHTML = d.members.map(id => {
                let m = members.find(x => x.id === id);
                return `<div class="member-box">${m.icon || "🙂"} ${m.name}</div>`;
            }).join("");
    
            div.insertAdjacentHTML("beforeend",
                `<div style="margin-top:10px;">${memberHTML}</div>`
            );
    
            dishList.appendChild(div);
        });
    }
    
    
    // ============================
    //  花費計算
    // ============================
    function calculateCost() {
        let total = dishes.reduce((s, d) => s + d.price, 0);
        totalPrice.innerText = total;
    
        costList.innerHTML = "";
    
        members.forEach(m => {
            let cost = 0;
            dishes.forEach(d => {
                if (d.members.includes(m.id)) {
                    cost += d.price / d.members.length;
                }
            });
    
            let box = document.createElement("div");
            box.className = "member-box";
            box.innerHTML = `${m.name}：$${cost.toFixed(1)}`;
            costList.appendChild(box);
        });
    }
    
    
    // ============================
    //  儲存並重置
    // ============================
    function finishAndReset() {
        if (!storeData.name) return alert("請先輸入店家資訊！");
        if (!members.length) return alert("請先加入成員！");
        if (!dishes.length) return alert("請至少加入一份餐點！");
    
        history.push({
            date: getDate(),
            store: {...storeData},
            members: JSON.parse(JSON.stringify(members)),
            dishes: JSON.parse(JSON.stringify(dishes)),
            total: dishes.reduce((s, d) => s + d.price, 0)
        });
    
        // === 清空所有資料 ===
        storeData = { name:"", img:"", fav:false, address:"" };
        members = [];
        dishes = [];
    
        storeImg.src = "";
        storeName.innerText = "尚未輸入";
        storeFav.classList.remove("fav");
        addressInput.value = "";
        mapStatus.style.color = "gray";
    
        renderMembers();
        renderDishes();
        calculateCost();
    
        switchPage("history");
    }
    
    function getDate() {
        return `${year.value}/${month.value}/${day.value} ${hour.value}:${minute.value}`;
    }
    
    
    // ============================
    //  歷史紀錄（含刪除）
    // ============================
    function renderHistory() {
        historyList.innerHTML = "";
    
        history.forEach((h, index) => {
            let div = document.createElement("div");
            div.className = "row";
    
            let del = document.createElement("button");
            del.innerText = "刪除紀錄";
            del.onclick = () => {
                history.splice(index, 1);
                renderHistory();
            };
    
            div.innerHTML = `
                <div><strong>${h.date}</strong></div>
                <div>店家：${h.store.name}（總額 $${h.total}）</div>
            `;
            
            div.appendChild(del);
            historyList.appendChild(div);
        });
    }
    
    
    // ============================
    //  喜歡的店家 / 餐點
    // ============================
    function renderFavStores() {
        favStoreList.innerHTML = "";
        if (storeData.fav && storeData.name) {
            favStoreList.innerHTML = `<div class="row">${storeData.name}</div>`;
        }
    }
    
    function renderFavDishes() {
        favDishList.innerHTML = "";
    
        dishes.filter(d => d.fav).forEach(d => {
            let div = document.createElement("div");
            div.className = "row";
            div.innerHTML = `
                <img src="${d.img}" class="preview">
                <span>${d.name} ($${d.price})</span>
            `;
            favDishList.appendChild(div);
        });
    }
    
    </script>
    