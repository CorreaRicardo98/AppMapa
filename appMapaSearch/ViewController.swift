//
//  ViewController.swift
//  appMapaSearch
//
//  Created by Mac17 on 05/05/21.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController,MKMapViewDelegate {
 
    var latitud:CLLocationDegrees?
    var longitud:CLLocationDegrees?
    var altitud:Double?
    @IBOutlet weak var buscador: UISearchBar!
    
    var manager = CLLocationManager()
    @IBOutlet weak var mapaMK: MKMapView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        manager.delegate = self
        buscador.delegate = self
        mapaMK.delegate = self
        
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        // Do any additional setup after loading the view.
    }
    
    //MARK:- trasar ruta
    func trazarRuta(destino:CLLocationCoordinate2D){
        if let origen = manager.location?.coordinate{
            let origin = MKPlacemark(coordinate: origen)
            let destiny = MKPlacemark(coordinate: destino)
            
            

            
            
            let origenItem = MKMapItem(placemark: origin)
            let destinoItem = MKMapItem(placemark: destiny)
            
            let solicitud = MKDirections.Request()
            
            solicitud.source = origenItem
            solicitud.destination = destinoItem
            
            solicitud.transportType = .automobile
            
            solicitud.requestsAlternateRoutes = true
            
            let direcciones = MKDirections(request: solicitud)
            direcciones.calculate { (respuesta, error) in
                if let respuestaS = respuesta {
                    if let error = error{
                        print(error.localizedDescription)
                    }else{
                        let ruta = respuestaS.routes[0]
                        self.mapaMK.addOverlay(ruta.polyline)
                        self.mapaMK.setVisibleMapRect(ruta.polyline.boundingMapRect, animated: true)
                    }
                }
            }

        }
    }
    
    func tenerDistancia(destino:CLLocation){
        if let origen = manager.location{
            let distancia = origen.distance(from: destino)
            let distanciaKM = distancia/1000;
            
            let distanciaString = String(format: "%.3f", distanciaKM)
            
            let alerta = UIAlertController(title: "Distancia en (Km)", message: "la distancia entre tu ubicación y el lugar elegido es: \(distanciaString)Km", preferredStyle: .alert)
            
            let accionAceptar = UIAlertAction(title: "Ok", style: .default, handler: nil)
            
            alerta.addAction(accionAceptar)
            present(alerta, animated: true, completion: nil)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .cyan
        
        return render
    }

    @IBAction func ubicacion(_ sender: Any) {
        let alerta = UIAlertController(title: "Ubicación", message: "Coordenadas: (\(latitud ?? 0),\(longitud ?? 0)) con altitud: \(altitud ?? 0)", preferredStyle: .alert)
        
        let accionAceptar = UIAlertAction(title: "Aceptar", style: .default, handler: nil)
        
        alerta.addAction(accionAceptar)
        
        present(alerta, animated: true, completion: nil)
        
        let localizacion = CLLocationCoordinate2D(latitude:latitud!,longitude:longitud!)
        
        let snapMapa = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        
        let region = MKCoordinateRegion(center: localizacion, span: snapMapa)
        
        mapaMK.setRegion(region, animated: true)
        mapaMK.showsUserLocation = true
    }
}

extension ViewController:CLLocationManagerDelegate,UISearchBarDelegate{
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let ubicacion = locations.first else{
            return
        }
        latitud = ubicacion.coordinate.latitude
        longitud = ubicacion.coordinate.longitude
        altitud = ubicacion.altitude
        
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("erroro al obtener: \(error.localizedDescription)")
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        

        print("Ubicacion encontrada!")
        buscador.resignFirstResponder()
        
        let geocoder = CLGeocoder()
        
        if let direccion = buscador.text{
            geocoder.geocodeAddressString(direccion) { (places:[CLPlacemark]?, error:Error?) in
                
                
                guard let rutaS = places?.first?.location else{
                    return
                }
                if error == nil{
                    // buscar direccion
                    let lugar = places?.first
                    let anotacion = MKPointAnnotation()
                    anotacion.coordinate = (lugar?.location?.coordinate)!
                    anotacion.title = direccion
                    
                    let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    
                    let region = MKCoordinateRegion(center: anotacion.coordinate, span: span)
                    
                    self.mapaMK.setRegion(region, animated: true)
                    self.mapaMK.addAnnotation(anotacion)
                    self.mapaMK.selectAnnotation(anotacion, animated: true)
                    
                    self.trazarRuta(destino: rutaS.coordinate)
                    
                    self.tenerDistancia(destino: rutaS)
                    
                    
                    
                }else{
                    print("error: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
}

