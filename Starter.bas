B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=9.9
@EndOfDesignText@
Sub Process_Globals
	Private smsInt As SmsInterceptor
	Private player As MediaPlayer
	Public player As MediaPlayer ' Изменили Private на Public
	Private smsInt As SmsInterceptor
	Private p As Phone ' Добавляем объект Phone для управления громкостью
	Public SelectedNumbers As List
	Public Keywords As String = "ОПАСНОСТЬ, ТРЕВОГА"
	Public AlarmFileDir As String = File.DirAssets
	Public AlarmFileName As String = "alarm.mp3"
End Sub

Sub Service_Create
	smsInt.Initialize("sms")
	player.Initialize
	If File.Exists(File.DirAssets, "alarm.mp3") Then
		player.Load(File.DirAssets, "alarm.mp3")
		player.Looping = True ' Включаем бесконечный повтор
	End If
End Sub

Sub sms_MessageReceived (From As String, Body As String) As Boolean
	Log("SMS от: " & From & " Текст: " & Body)
	
	' 1. Проверяем, есть ли отправитель в списке выбранных в Main
	Dim isAllowedSender As Boolean = False
	For Each num As String In Main.SelectedNumbers
		If From.Contains(num) Then
			isAllowedSender = True
			Exit
		End If
	Next
	
	' 2. Проверяем наличие ключевых слов (из поля ввода в Main)
	Dim isKeywordFound As Boolean = False
	' Разбиваем строку по запятой и проверяем каждое слово
	Dim words() As String = Regex.Split(",", Main.Keywords)
	For Each w As String In words
		If Body.ToUpperCase.Contains(w.Trim.ToUpperCase) Then
			isKeywordFound = True
			Exit
		End If
	Next
	
	' 3. Если номер и текст совпали — включаем тревогу
	If isAllowedSender And isKeywordFound Then
		Log("Условия совпали! Перезапуск сирены...")
		Dim i As Intent
		i.Initialize(i.ACTION_MAIN, "")
		i.SetComponent("b4a.example/.main") ' ЗАМЕНИТЕ b4a.example на ваш Package Name из Project -> Build Configurations
		i.Flags = 268435456 ' FLAG_ACTIVITY_NEW_TASK
		StartActivity(i)
		If Main.MaxVolumeEnabled Then
			Dim p As Phone
			p.SetVolume(p.VOLUME_MUSIC, p.GetMaxVolume(p.VOLUME_MUSIC), True)
		End If	
        
		' 2. ПРИНУДИТЕЛЬНЫЙ СБРОС И ПЕРЕЗАГРУЗКА
		If player.IsPlaying Then player.Stop
        
		' ЗАГРУЖАЕМ ВЫБРАННЫЙ ПОЛЬЗОВАТЕЛЕМ ФАЙЛ
		player.Load(Main.AlarmFileDir, Main.AlarmFileName)
		player.Looping = True ' Включаем повтор
        
		' 3. Запуск
		player.Play
        
		Return True
	End If
	
	Return False ' Обычное SMS
End Sub

Sub ReloadPlayer
	If player.IsPlaying Then player.Stop
    
	Try
		' 1. Сначала пробуем загрузить файл пользователя
		If Main.AlarmFileDir = File.DirAssets Then
			player.Load(File.DirAssets, Main.AlarmFileName)
		Else
			' Используем универсальный метод для внешних файлов
			player.Load(Main.AlarmFileDir, Main.AlarmFileName)
		End If
        
		player.Looping = True
		Log("Файл успешно загружен: " & Main.AlarmFileName)
        
	Catch
		Log("Ошибка файла! Грузим стандартный alarm.mp3")
		Try
			player.Load(File.DirAssets, "alarm.mp3")
			player.Looping = True
		Catch
			Log("Стандартный файл тоже не найден!")
		End Try
	End Try
End Sub

Sub StartSiren
	' Добавим проверку перед запуском
	If player.IsInitialized Then
		player.Play
		Log("Сирена запущена")
	Else
		Log("Ошибка: Плеер не инициализирован")
	End If
End Sub
