#!/usr/bin/env python3
"""
Test di integrazione per bSmart Dynamic
Verifica che il servizio sia correttamente integrato nel sistema
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

import utils

def test_service_registration():
    """Test 1: Verifica che bsmdynamic sia registrato"""
    print("=" * 60)
    print("Test 1: Verifica Registrazione Servizio")
    print("=" * 60)
    
    if "bsmdynamic" in utils.services:
        print("✅ bsmdynamic è registrato nei servizi")
        print(f"   Nome: {utils.services['bsmdynamic']}")
        return True
    else:
        print("❌ bsmdynamic NON è registrato")
        return False


def test_service_loading():
    """Test 2: Verifica che il modulo sia caricabile"""
    print("\n" + "=" * 60)
    print("Test 2: Verifica Caricamento Modulo")
    print("=" * 60)
    
    try:
        service = utils.getservice("bsmdynamic")
        print("✅ Modulo bsmdynamic caricato correttamente")
        
        # Verifica che abbia le funzioni richieste
        required_functions = ['login', 'library', 'downloadbook', 'checktoken']
        missing = []
        
        for func in required_functions:
            if hasattr(service, func):
                print(f"   ✓ Funzione '{func}' presente")
            else:
                print(f"   ✗ Funzione '{func}' MANCANTE")
                missing.append(func)
        
        if missing:
            print(f"\n❌ Funzioni mancanti: {', '.join(missing)}")
            return False
        
        print("\n✅ Tutte le funzioni richieste sono presenti")
        return True
        
    except Exception as e:
        print(f"❌ Errore nel caricamento: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


def test_key_extractor():
    """Test 3: Test del key extractor (opzionale - richiede connessione)"""
    print("\n" + "=" * 60)
    print("Test 3: Test Key Extractor (Opzionale)")
    print("=" * 60)
    print("⚠️  Questo test richiede connessione internet")
    
    try:
        user_input = input("Vuoi testare l'estrazione della chiave? (y/n): ").lower()
        
        if user_input != 'y':
            print("⏭️  Test saltato")
            return True
        
        print("\n🔄 Estrazione chiave in corso...")
        service = utils.getservice("bsmdynamic")
        
        # Testa l'estrazione della chiave
        key = service.get_encryption_key()
        
        print(f"\n✅ Chiave estratta con successo!")
        print(f"   Lunghezza: {len(key)} bytes")
        print(f"   Hex: {key.hex()}")
        
        # Confronta con chiave vecchia
        old_key = bytes.fromhex("1e00b89873139d2104ed501a8bf8689b")
        if key == old_key:
            print("   ℹ️  Corrisponde alla vecchia chiave hardcoded")
        else:
            print("   ⚠️  Diversa dalla vecchia chiave - bSmart ha aggiornato!")
        
        return True
        
    except KeyboardInterrupt:
        print("\n⏭️  Test interrotto")
        return True
    except Exception as e:
        print(f"\n❌ Errore: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


def test_service_listing():
    """Test 4: Verifica lista servizi nell'API"""
    print("\n" + "=" * 60)
    print("Test 4: Verifica Lista Servizi")
    print("=" * 60)
    
    print("\nServizi disponibili:")
    print("-" * 60)
    
    # Mostra tutti i servizi con evidenza per bsmart
    for code, name in utils.services.items():
        if code in ["bsm", "bsmdynamic"]:
            print(f"  🔹 {code:15} → {name}")
        else:
            print(f"     {code:15} → {name}")
    
    print("\n✅ Lista servizi verificata")
    print(f"   Totale servizi: {len(utils.services)}")
    
    bsmart_services = [k for k in utils.services.keys() if 'bsm' in k]
    print(f"   Servizi bSmart: {bsmart_services}")
    
    return True


def main():
    """Esegue tutti i test"""
    print("\n" + "=" * 60)
    print("🧪 TEST INTEGRAZIONE BSMART DYNAMIC")
    print("=" * 60)
    print()
    
    results = []
    
    # Test 1: Registrazione
    results.append(("Registrazione Servizio", test_service_registration()))
    
    # Test 2: Caricamento modulo
    results.append(("Caricamento Modulo", test_service_loading()))
    
    # Test 3: Key extractor (opzionale)
    results.append(("Key Extractor", test_key_extractor()))
    
    # Test 4: Lista servizi
    results.append(("Lista Servizi", test_service_listing()))
    
    # Riepilogo
    print("\n" + "=" * 60)
    print("📊 RIEPILOGO TEST")
    print("=" * 60)
    
    passed = 0
    for name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{name:25} {status}")
        if result:
            passed += 1
    
    total = len(results)
    print(f"\n{'=' * 60}")
    print(f"Risultato: {passed}/{total} test superati")
    
    if passed == total:
        print("\n🎉 Tutti i test sono stati superati!")
        print("\n✨ bSmart Dynamic è pronto per l'uso!")
        print("\nPer usarlo:")
        print("  1. Avvia l'interfaccia web: ./start.sh")
        print("  2. Vai su http://localhost:6066")
        print("  3. Seleziona 'bSmart Dynamic (Auto-Key)' dalla lista")
        print("  4. Fai login e scarica i tuoi libri!")
        print(f"\n{'=' * 60}\n")
        return 0
    else:
        print("\n⚠️  Alcuni test sono falliti")
        print("Verifica i log sopra per i dettagli")
        print(f"\n{'=' * 60}\n")
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n⏹️  Test interrotti dall'utente")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Errore fatale: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

