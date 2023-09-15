//
//  ViewController.swift
//  CoreDataProjectUdemyAtil
//
//  Created by Dilan Öztürk on 17.03.2023.
//

import UIKit
import CoreData

// veriler telefonun hafızasına kaydedilir. kullanıcı uygulamayı silmediği sürece veriler kayıtlı kalır. bu bilgiler internette de saklanabilir (firebase gibi sunucular) ama o konuya sonra geçicez. core data lokal bir veri tabanıdır. uygulamaya girilen belli verileri hafızaya kaydeder. core data apple ın kendi ürettiği bir teknoloji
// kullanıcının kaydettiği veri viewcontroller da çekilecek ve tableView da gösterilecek. isim ve id gösterilmesi yeterli olacak. verinin eşsiz bir id si olması veriler çekilirken sadece o datayı çekme komutu verir diğer datalar çekilmez ve performans hızlanır

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedPainting = ""
    var selectedPaintingId = UUID()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        getData() // fonksiyonu sayfa açıldığında çağırıyoruz
    }
    
    override func viewWillAppear(_ animated: Bool) { // save e tıklanınca tableView da kaydedilen ismin gözükmesi için viewDidLoad kullanamayız çünkü viewDidLoad sadece bir kere çağırılır uygulama açıldığında. viewWillAppear her viewController açıldığında fonksiyonu çağırır
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newData"), object: nil) // selector, bu mesajı alırsak napayım diye sorar. bu mesajı alınca getData yı çağıracak. bunu yaptıktan sonra tableView da isimler gözükür ama birden fazla kopyası çıkar. bundan kurtulmak için getData fonksiyonuna gidip nameArray-idArray.removeAll(keepingCapacity: false) yazılır

    }
    
    @objc func getData() { // coredata dan verileri çekiyoruz
        
        nameArray.removeAll(keepingCapacity: false) // tableview da birden fazla kopya gözükmesini engeller
        idArray.removeAll(keepingCapacity: false)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate // önce AppDelegate a ulaşıyoruz
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings") // dataları çekme isteği
        fetchRequest.returnsObjectsAsFaults = false // bunu false yapınca işlem daha hızlı gerçekleşir
        
        do{
            let results = try context.fetch(fetchRequest) // geri gelecek cevap bir dizi içerisinde verilir. dizi olduğu için birden fazla result olur
            if results.count > 0 { // results 0 dan büyükse geri kalanı yap
                
                for result in results  as! [NSManagedObject] { // results bir dizi olmuş oluyor. yukarıdan gelen diziyi tek tek incelemeye olanak sağlar. tek bir result a odaklanabilmek için as! NSManagedObject diye cast etmek gerekir
                    if let name = result.value(forKey: "name") as? String { // artık anahtar kelime verilince isme ulaşılır. if let le yazmanın sebebi eğer bu gerçekleşirse işlemi yapmak. burda yaptığımız şey userDefaults ile aynı. bir anahtar kelime veriyoruz o bize bir any object veriyor biz bunu string olarak cast etmeye çalışıyoruz cast edebilirsek işlem yapıcaz edemezsek yapmıycaz
                        self.nameArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    self.tableView.reloadData() // bi veri yükledikten sonra tableView ı refresh etmek lazım. yani burada yeni bir veri geldi kendini güncelle diyoruz
                }
            }
        }catch{
            print("error")
        }
    }
    
    @objc func addButtonClicked () {
        
        selectedPainting = "" // artıya tıklandıysa bir görsel seçilmedi
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.chosenPainting = selectedPainting // seçilen resmin ismini diğer controller a aktarıyoruz
            destinationVC.chosenPaintingId = selectedPaintingId // seçilen resmin görselini diğer controller a aktarıyoruz
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPainting = nameArray[indexPath.row] // bir resmin ismine tıklandıysa isme tıklandığını belirtiyoruz
        selectedPaintingId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) { // silme işlemi
        
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = ½@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try! context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject]{
                        if let id = result.value(forKey: "id") as? UUID {
                            if id == idArray[indexPath.row]{
                                context.delete(result) // coredata dan silicek
                                nameArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData() // tableview ı da kendine getir çünkü bazı kayıtlar silinmiş olucak
                                
                                do {
                                    try context.save() // core datada yaptığımız işlemi bitiriyoruz
                                }catch{
                                    print(error)
                                }
                                
                                break // biz id ile çalıştığımız için yapımız sağlam ama id ile değil isim ile silmeye çalışsaydık bir sürü sonuç olucaktı ve for loop içinde dönüp dönüp bakıcaktı ve isimler eşitse silicekti. aranılan şey bulunmuşsa ve silinmişse for loop un devam etmesine gerek yoktur bu yüzden break kullanılır. yani for loop tan çıkmak için break kullanılır
                            }
                        }
                    }
                            
                }
            }
        }
    }


}

