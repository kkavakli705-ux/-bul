package com.example.isbul

import android.widget.Toast
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun SettingsScreen(
    email: String = "kkavakli705@gmail.com",
    onBackClick: () -> Unit = {}
) {

    val context = LocalContext.current

    var notificationsEnabled by remember {
        mutableStateOf(true)
    }

    var showPrivacyDialog by remember {
        mutableStateOf(false)
    }

    var showTermsDialog by remember {
        mutableStateOf(false)
    }

    var showAboutDialog by remember {
        mutableStateOf(false)
    }

    var showPasswordDialog by remember {
        mutableStateOf(false)
    }

    val backgroundColor = Color(0xFFF8F8FF)
    val cardColor = Color(0xFFF0F0F8)
    val iconColor = Color(0xFF50545C)
    val blueColor = Color(0xFF3478A8)

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = backgroundColor
    ) {

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 22.dp)
        ) {

            Spacer(modifier = Modifier.height(40.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {

                IconButton(
                    onClick = onBackClick
                ) {
                    Icon(
                        imageVector = Icons.Default.ArrowBack,
                        contentDescription = "Geri",
                        tint = Color.Black,
                        modifier = Modifier.size(32.dp)
                    )
                }

                Spacer(modifier = Modifier.width(25.dp))

                Text(
                    text = "Ayarlar",
                    fontSize = 31.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
            }

            Spacer(modifier = Modifier.height(40.dp))

            // HESABIM
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(130.dp),
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(
                    containerColor = cardColor
                ),
                elevation = CardDefaults.cardElevation(
                    defaultElevation = 3.dp
                )
            ) {

                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 25.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {

                    Icon(
                        imageVector = Icons.Default.AccountCircle,
                        contentDescription = null,
                        tint = iconColor,
                        modifier = Modifier.size(43.dp)
                    )

                    Spacer(modifier = Modifier.width(25.dp))

                    Column {

                        Text(
                            text = "Hesabım",
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = email,
                            fontSize = 17.sp,
                            color = iconColor
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // ŞİFRE DEĞİŞTİR
            SettingsButton(
                icon = Icons.Default.LockReset,
                title = "Şifremi Değiştir",
                subtitle = "E-posta adresine şifre sıfırlama bağlantısı gönder",
                cardColor = cardColor,
                iconColor = iconColor,
                onClick = {
                    showPasswordDialog = true
                }
            )

            Spacer(modifier = Modifier.height(14.dp))

            // BİLDİRİMLER
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(130.dp),
                shape = RoundedCornerShape(22.dp),
                colors = CardDefaults.cardColors(
                    containerColor = cardColor
                ),
                elevation = CardDefaults.cardElevation(
                    defaultElevation = 3.dp
                )
            ) {

                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(horizontal = 25.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {

                    Icon(
                        imageVector = Icons.Default.Notifications,
                        contentDescription = null,
                        tint = iconColor,
                        modifier = Modifier.size(38.dp)
                    )

                    Spacer(modifier = Modifier.width(27.dp))

                    Column(
                        modifier = Modifier.weight(1f)
                    ) {

                        Text(
                            text = "Bild
