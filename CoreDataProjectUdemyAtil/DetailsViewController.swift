//
//  DetailsViewController.swift
//  CoreDataProjectUdemyAtil
//
//  Created by Dilan Öztürk on 17.03.2023.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var artistText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var chosenPainting = "" // bi şey seçilmezse boş yollatıcaz
    var chosenPaintingId : UUID? // uuid optional. bi şey seçilirse dolu yollatıcaz
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if chosenPainting != "" { // boş değilse data çekicez
            
            saveButton.isEnabled = false // savebutton ı tıklanamaz hale getirir. isHidden da yapılır ama bu sefer hiç gözükmez olur
            
            //core data
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            let idString = chosenPaintingId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString) // "id = ½@" bu id si yandakine(idString) eşit olan şeyi bul demek
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                
                let results = try context.fetch(fetchRequest) // bi değişkene eşitliyoruz. bu değişken bize bir dizi veriyor. bu dizileri tek tek for loop a sokabiliyoruz
                
                if results.count > 0 { // results 0 dan büyükse geri kalanı yap
                    
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "name") as? String {
                            nameText.text = name
                        }
                        if let artist = result.value(forKey: "artist") as? String {
                            artistText.text = artist
                        }
                        if let year = result.value(forKey: "year") as? Int {
                            yearText.text = String(year)
                        }
                        if let imageData = result.value(forKey: "image") as? Data {
                            let image = UIImage(data: imageData)
                            imageView.image = image
                        }
                    }
                }
            } catch {
                print(error)
            }
            
            //let stringUUID = chosenPaintingId!.uuidString -> bu kodu id lerin nasıl çalıştığını anlamak için yazdı hoca. print edince konsolda her bir basılan resim adının farklı bir id si olduğu görülüyor
            //print(stringUUID)
            
        } else { // boşsa ne gösteriliyosa o gösterilcek
            
            saveButton.isHidden = false // görünür olsun
            saveButton.isEnabled = false // ama tıklanamasın
            nameText.text = ""
            artistText.text = ""
            yearText.text = "" // bunlar zaten boş geliceği için bunları yazmasak da olur
        }

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard)) // kullanıcı textfield a tıkladığında keyboard çıkıyor ancak bu keyboard save kısmını kapatabiliyor. o yüzden dışarı tıklandığında keyboardun kapanması gerek
        view.addGestureRecognizer(gestureRecognizer) // view da herhangi bir yere tıklandığında keyboard kapanacak
        
        imageView.isUserInteractionEnabled = true
        let imageTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage)) // kullanıcı görsele tıkladığında galerisine gidecek
        imageView.addGestureRecognizer(imageTapRecognizer)
    }
    
    @objc func hideKeyboard () {
        
        view.endEditing(true)
    }
    
    @objc func selectImage () {
        
        let picker = UIImagePickerController() // UIImagePickerController kullanıcının kütüphanesine erişmek için kullandığımız bir sınıftır
        picker.delegate = self // picker ın fonksiyonlarını kullanmak için
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true // kullanıcı görseli seçtiğinde editlemesini sağlayan bir şeyle karşılaşır
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) { // görseli seçtikten sonrası. bu fonksiyon UIImagePickerController ın info sunu ve any type ını döndürür
        imageView.image = info[.originalImage] as? UIImage
        saveButton.isEnabled = true // saveButton görünür olsun
        self.dismiss(animated: true) // seçilen resim viewcontroller a aktarılacak
    }

   
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate // konsepte ulaşabilmek için AppDelegate ı bir değişken olarak tanımlamak lazım
        let context = appDelegate.persistentContainer.viewContext // bu context i kullanarak biraz önce bana verilen supporting fonksiyonlarını kullanabilicez
        let newPainting = NSEntityDescription.insertNewObject(forEntityName: "Paintings", into: context) // insertNewObject yeni bir obje koymamızı sağlar. into kısmına da kaydedilecek konteks yazılır
        
        // Attributes (infonun altındaki dosyada)
        newPainting.setValue(nameText.text, forKey: "name") // paintings entity nin içine veriyi kaydediyoruz
        newPainting.setValue(artistText.text, forKey: "artist")
        if let year = Int(yearText.text!) { // year ı int e çevirmek için böyle yazılır
            newPainting.setValue(year, forKey: "year")
        }
        newPainting.setValue(UUID(), forKey: "id") // her seferinde bu işlem yapıldığında kendisi baştan eşsiz bir id oluşturup buraya kaydedecek
        let data = imageView.image!.jpegData(compressionQuality: 0.5) // uiimage ı bir data olarak kaydediyoruz. compressionQuality e yüzde kaçını alıp küçülterek veriye çevireceği yazılır. büyük boyutlu görselleri küçültmek iyidir
        newPainting.setValue(data, forKey: "image")
        
        do {
            try context.save() // core data ya veri yüklememize olanak sağlayacak fonksiyon. save i yazarken tanımlamanın yanında throws yazar. bu bir hata çıkabilir anlamına gelir. o yüzden do try catch yapılır
            print("success")
        }catch{
            print("error")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)// NotificationCenter kullanılarak viewController lar arası belli mesajlar yollanabilir. buranın devamında ViewController a gidip viewWillAppaer fonksiyonu yazılır
        self.navigationController?.popViewController(animated: true) // save tıklanınca bir önceki viewController a git. ancak kaydedildiği halde uygulamayı kapatıp açmadıkça tableview da gözükmüyor. bunu çözmek içine bi üstteki kod yazılır
        
    }
    
    

}
