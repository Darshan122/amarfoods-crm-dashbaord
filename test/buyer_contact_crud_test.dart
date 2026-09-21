import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_crm_app/models/buyer.dart';
import 'package:buyer_crm_app/models/buyer_contact.dart';

void main() {
  test('Parses legacy corrupted contacts string from screenshot perfectly', () {
    const rawNote =
        '[CONTACTS: Andrew Crovo [Procurement] (http://linkedin.com/in/andrewcrovo/); Jameka Pope [Purchasing] (https://www.linkedin.com/in/jameka-pope/); Tyler Christner (https://www.linkedin.com/in/tyler-christner-0b9700b7/); Heather Amanda Reis [Procurement] (https://www.linkedin.com/in/heather-amanda-reis-b398073b2/)]';

    final buyer = Buyer(
      id: 'AF-00204',
      srNo: 204,
      company: 'Elite Spice, Inc',
      website: 'https://elitespice.com',
      email: '',
      phone: '',
      connectionMethod: 'LinkedIn',
      connectionDate: '2026-09-21',
      firstEmailDate: '',
      nextDueDate: '',
      clientReply: 'Pending',
      lastEmailDate: '',
      followupCount: 0,
      status: 'New',
      nextAction: 'Follow-Up',
      notes: rawNote,
      marketType: 'International',
    );

    final contacts = buyer.contacts;
    expect(contacts.length, 4);

    expect(contacts[0].name, 'Andrew Crovo');
    expect(contacts[0].role, 'Procurement');
    expect(contacts[0].linkedInUrl, 'http://linkedin.com/in/andrewcrovo/');

    expect(contacts[1].name, 'Jameka Pope');
    expect(contacts[1].role, 'Purchasing');
    expect(contacts[1].linkedInUrl, 'https://www.linkedin.com/in/jameka-pope/');

    expect(contacts[2].name, 'Tyler Christner');
    expect(contacts[2].linkedInUrl, 'https://www.linkedin.com/in/tyler-christner-0b9700b7/');

    expect(contacts[3].name, 'Heather Amanda Reis');
    expect(contacts[3].role, 'Procurement');
    expect(contacts[3].linkedInUrl, 'https://www.linkedin.com/in/heather-amanda-reis-b398073b2/');

    // Ensure notesWithoutContacts leaves no residual leaked contact fragments
    expect(buyer.notesWithoutContacts, isEmpty);

    // Now test re-embedding in new format
    final updatedNote = Buyer.embedContactsInNotes('Real buyer note about onion mesh', contacts);
    expect(updatedNote.contains('<<<CONTACTS_START>>>'), isTrue);
    expect(updatedNote.contains('<<<CONTACTS_END>>>'), isTrue);

    final buyer2 = buyer.copyWith(notes: updatedNote);
    final contacts2 = buyer2.contacts;
    expect(contacts2.length, 4);
    expect(contacts2[0].name, 'Andrew Crovo');
    expect(contacts2[1].name, 'Jameka Pope');
    expect(contacts2[1].role, 'Purchasing');
    expect(contacts2[2].name, 'Tyler Christner');
    expect(contacts2[3].name, 'Heather Amanda Reis');
    expect(buyer2.notesWithoutContacts, 'Real buyer note about onion mesh');
  });
}
