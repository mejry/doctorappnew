const Prescription = require('../models/prescription');
const Medication = require('../models/Medication');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');
const logger = require('../utils/logger');
const axios = require('axios');
const EmailService = require('./emailService');

const { publishPrescriptionCreated } = require('../events/publishers/prescriptionPublisher');

const { publishEvent, consumeEvents } = require('../utils/rabbit');

const ConsultationCache = require('./consultationCache');


function escapeRegex(text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

class PrescriptionService {
  // 🆕 NOUVELLE MÉTHODE: Obtenir suggestions IA
async getAISuggestions(consultationId) {
    try {
      console.log(`🤖 Récupération données réelles pour consultation: ${consultationId}`);
      
      // 1. Récupérer consultation via route interne (PAS D'AUTH REQUISE)
      const responseConsultation = await axios.get(
        `http://localhost:8003/api/consultations/internal/${consultationId}`, 
        { timeout: 10000 }
      );
      const consultation = responseConsultation.data;
      console.log(`✅ Consultation récupérée:`, consultation);
      
      // 2. Récupérer données patient via ROUTE INTERNE (PAS D'AUTH REQUISE)
      let patient;
      try {
        const responsePatient = await axios.get(
          `http://localhost:8002/api/patients/internal/${consultation.patientId}`, 
          { timeout: 10000 }
        );
        patient = responsePatient.data;
        console.log(`✅ Patient récupéré:`, patient);
      } catch (error) {
        console.log('⚠️ Impossible de récupérer le patient, utilisation de données par défaut');
        patient = {
          firstName: "Test",
          lastName: "Patient", 
          age: 45,
          gender: "Female",
          dob: "1978-06-25"
        };
      }
      
      // 3. Récupérer historique médical via ROUTE INTERNE (PAS D'AUTH REQUISE)
      let medicalHistory;
      try {
        const responseMedical = await axios.get(
          `http://localhost:8002/api/patients/internal/${consultation.patientId}/medical-history`, 
          { timeout: 10000 }
        );
        medicalHistory = responseMedical.data[0] || {};
        console.log(`✅ Historique médical récupéré:`, medicalHistory);
      } catch (error) {
        console.log('⚠️ Pas d\'historique médical, utilisation de valeurs par défaut');
        medicalHistory = {
          bloodPressure: "150/95",
          heartRate: 85,
          bloodGlucoseLevel: 145,
          oxygenSaturation: 96,
          respiratoryRate: 18,
          bodyTemperature: 37.2,
          weight: 82,
          height: 175,
          smokingStatus: "Ex-smoker",
          alcoholConsumption: "Occasionally"
        };
      }
      
      // 4. Calculer l'âge si nécessaire
      let age = patient.age;
      if (!age && patient.dob) {
        const dob = new Date(patient.dob);
        const today = new Date();
        age = Math.floor((today - dob) / (365.25 * 24 * 60 * 60 * 1000));
      }
      
      // 5. Enrichir les données pour l'IA avec des valeurs réalistes
      const enrichedPatientData = {
        age: age || 45,
        gender: patient.gender ? patient.gender.toLowerCase() : "female",
        medical_history: {
          // Signes vitaux du patient ou valeurs par défaut réalistes
          bloodPressure: medicalHistory.bloodPressure || "150/95",
          heartRate: medicalHistory.heartRate || 85,
          bloodGlucoseLevel: medicalHistory.bloodGlucoseLevel || 145,
          oxygenSaturation: medicalHistory.oxygenSaturation || 96,
          respiratoryRate: medicalHistory.respiratoryRate || 18,
          bodyTemperature: medicalHistory.bodyTemperature || 37.2,
          weight: medicalHistory.weight || 82,
          height: medicalHistory.height || 175,
          
          // Habitudes de vie
          smokingStatus: medicalHistory.smokingStatus || "Ex-smoker",
          alcoholConsumption: medicalHistory.alcoholConsumption || "Occasionally",
          
          // Conditions chroniques
          chronicDiseases: medicalHistory.chronicDiseases || ["hypertension", "diabetes type 2"],
          allergies: medicalHistory.allergies || []
        },
        consultation_data: {
          symptoms: consultation.symptoms?.length > 0 ? consultation.symptoms : ["headache", "dizziness", "fatigue"],
          diagnosis: consultation.diagnosis?.length > 0 ? consultation.diagnosis : ["hypertension", "diabetes"]
        }
      };
      
      console.log(`🔍 Données enrichies pour IA:`, JSON.stringify(enrichedPatientData, null, 2));
      
      // 6. Appeler le service IA avec données enrichies
      const aiResponse = await axios.post('http://localhost:5000/api/ia/predict-medications', {
        patient_data: enrichedPatientData
      }, {
        timeout: 15000,
        headers: { 'Content-Type': 'application/json' }
      });
      
      console.log(`✅ Suggestions IA reçues: ${aiResponse.data.predictions?.length || 0} médicaments`);
      return aiResponse.data;
      
    } catch (error) {
      console.error('❌ Erreur suggestions IA:', error.message);
      
      // Retourner des suggestions de fallback basées sur les symptômes/diagnostic
      const fallbackSuggestions = this.getFallbackSuggestions(consultationId);
      
      return { 
        success: false, 
        error: error.message,
        predictions: fallbackSuggestions,
        fallback: true
      };
    }
  }

 // 🆕 NOUVELLE MÉTHODE: Suggestions de fallback si l'IA est indisponible
  getFallbackSuggestions(consultationId) {
    // Suggestions basiques basées sur les conditions communes
    const commonSuggestions = [
      {
        medication: "paracetamol",
        confidence: 0.8,
        category: "analgésique",
        reason: "Médicament de base pour douleurs et fièvre"
      },
      {
        medication: "omeprazole",
        confidence: 0.7,
        category: "antiulcéreux",
        reason: "Protection gastrique"
      }
    ];
    
    console.log(`🔄 Utilisation des suggestions de fallback pour consultation: ${consultationId}`);
    return commonSuggestions;
  }


  async handleNewConsultation(consultationData) {

    try {
      console.log('consultationData', consultationData);

      const prescription = new Prescription({
        consultation: consultationData.consultationId,


        prescriptionInfo: {
          type: 'Regular',
          status: 'Pending',
          date: new Date(),
          time: new Date().toTimeString().slice(0, 5),
          notes: 'Prescription created automatically',

        },
        clinicalContext: {
          priority: 'Routine'
        }
      });

      await prescription.save();

      await publishPrescriptionCreated(prescription);




      logger.info(`Prescription created for consultation ${consultationData.consultationId}`);
      return prescription;
    } catch (error) {
      logger.error(`Error creating prescription: ${error.message}`);
      throw error;
    }
  }




  // async createPrescription(data) {
  //   const consultation = await ConsultationCache.getConsultation(data.consultation);
  //   if (!consultation) {
  //     throw new Error('Associated consultation not found');
  //   }
  //   // Verify all medications exist
  //   for (const med of data.medications) {
  //     const exists = await Medication.exists({ _id: med.medication });
  //     if (!exists) {
  //       throw new Error(`Medication ${med.medication} not found`);
  //     }
  //   }

  //   const prescription = new Prescription(data);
  //   await prescription.save();
  //   await publishEvent(
  //     'prescription.created',
  //     `prescription.${prescription._id}`,
  //     prescription.toObject()
  //   );

  //   return prescription;
  // }

  // Extrait du PrescriptionService - méthode createPrescription modifiée

// async createPrescription(data) {
//   const consultation = await ConsultationCache.getConsultation(data.consultation);
//   if (!consultation) {
//     throw new Error('Associated consultation not found');
//   }
  
//   // ✅ NOUVELLE VALIDATION - Plus flexible
//   for (const med of data.medications) {
//     // Si c'est un médicament de la base, vérifier qu'il existe
//     if (med.medication) {
//       const exists = await Medication.exists({ _id: med.medication });
//       if (!exists) {
//         throw new Error(`Medication ${med.medication} not found`);
//       }
//     }
//     // Si c'est un médicament libre, vérifier qu'il a un nom
//     else if (med.customMedication) {
//       if (!med.customMedication.name || med.customMedication.name.trim() === '') {
//         throw new Error('Custom medication must have a name');
//       }
//     }
//     // Si ni l'un ni l'autre
//     else {
//       throw new Error('Each medication must have either a medication reference or customMedication.name');
//     }
//   }

//   const prescription = new Prescription(data);
//   await prescription.save();
//   await publishEvent(
//     'prescription.created',
//     `prescription.${prescription._id}`,
//     prescription.toObject()
//   );

//   return prescription;
// }


// Modification de la méthode createPrescription dans prescriptionService.js
// Modification de la méthode createPrescription dans prescriptionService.js
async createPrescription(data) {
  console.log('🔍 DÉBUT createPrescription - Données reçues:', JSON.stringify(data, null, 2));
  
  // ✅ CORRECTION: Utiliser await car getConsultation est maintenant asynchrone
  const consultation = await ConsultationCache.getConsultation(data.consultation);
  if (!consultation) {
    console.error(`❌ Consultation non trouvée: ${data.consultation}`);
    throw new Error('Associated consultation not found');
  }
  
  console.log('📋 Consultation trouvée:', consultation);
  console.log('💊 Medications à traiter:', data.medications?.length || 0);
  
  // Validation détaillée des médicaments
  for (let i = 0; i < data.medications.length; i++) {
    const med = data.medications[i];
    console.log(`🔍 Médicament ${i + 1}:`, JSON.stringify(med, null, 2));
    
    // ✅ NOUVELLE VALIDATION - Plus flexible avec debug
    if (med.medication) {
      console.log(`   -> Type: DATABASE - Vérification ID: ${med.medication}`);
      const exists = await Medication.exists({ _id: med.medication });
      if (!exists) {
        console.error(`❌ Médicament ${med.medication} non trouvé en base`);
        throw new Error(`Medication ${med.medication} not found`);
      }
      console.log(`   ✅ Médicament de base validé`);
    } 
    else if (med.customMedication) {
      console.log(`   -> Type: CUSTOM - Nom: "${med.customMedication.name}"`);
      if (!med.customMedication.name || med.customMedication.name.trim() === '') {
        console.error(`❌ Médicament custom sans nom à l'index ${i}`);
        throw new Error('Custom medication must have a name');
      }
      console.log(`   ✅ Médicament custom validé`);
    } 
    else {
      console.error(`❌ Médicament ${i + 1} sans medication ni customMedication:`, med);
      throw new Error('Each medication must have either a medication reference or customMedication.name');
    }
    
    // Vérifier les dosages
    if (!med.dosage) {
      console.error(`❌ Pas de dosage pour le médicament ${i + 1}`);
      throw new Error(`Dosage information missing for medication ${i + 1}`);
    }
    console.log(`   ✅ Dosage présent:`, med.dosage);
  }

  console.log('✅ Validation terminée, création de la prescription...');
  
  const prescription = new Prescription(data);
  await prescription.save();
  
  console.log('✅ Prescription sauvegardée avec ID:', prescription._id);

  // Le reste du code reste identique...
  setImmediate(async () => {
    try {
      const aiSuggestions = await this.getAISuggestions(prescription.consultation);
      if (aiSuggestions.predictions && aiSuggestions.predictions.length > 0) {
        console.log('🤖 Suggestions IA disponibles:', 
          aiSuggestions.predictions.map(p => p.medication).slice(0, 3).join(', '));
        
        prescription.aiSuggestions = aiSuggestions.predictions;
        await prescription.save();
      }
    } catch (error) {
      console.warn('⚠️ IA indisponible, prescription créée sans suggestions');
    }
  });

  setImmediate(async () => {
    try {
      const responseConsultation = await axios.get(`http://localhost:8003/api/consultations/internal/${prescription.consultation}`);
      const responsePatient = await axios.get(`http://localhost:8002/api/patients/internal/${responseConsultation.data.patientId}`);
      const patientEmail = responsePatient.data.email;
      const patientName = `${responsePatient.data.firstName} ${responsePatient.data.lastName}`;
      
      await this.exportPrescriptionAsPDF(prescription._id);
      
      logger.info(`Prescription created and email sent to ${patientEmail}`);
    } catch (emailError) {
      logger.warn(`Prescription created but email failed: ${emailError.message}`);
    }
  });

  await publishEvent(
    'prescription.created',
    `prescription.${prescription._id}`,
    prescription.toObject()
  );

  console.log('🎉 Prescription créée avec succès !');
  return prescription;
}


  async getPrescriptionById(id) {
    return await Prescription.findById(id)
      .populate('medications.medication');
  }

  async getAllPrescriptions() {
    return await Prescription.find()
      .sort({ 'prescriptionInfo.date': -1 });
  }


  async updatePrescription(id, data) {
    // Prepare history entry



    const update = {
      $set: data,
      $push: {
        history: {
          action: 'Modifié',
          performedBy: 'API',  // Texte simple au lieu d'un ObjectId

          notes: 'updated prescription',
        }
      }
    };


    return await Prescription.findByIdAndUpdate(
      id,
      update,
      {
        new: true,
        runValidators: false
      }
    ).populate('medications.medication');
  }



  async deletePrescription(id) {
    const result = await Prescription.findByIdAndDelete(id);
    return !!result;
  }






  async searchPrescriptions(query) {
    const regex = new RegExp(escapeRegex(query), 'i');

    return await Prescription.find({
      $or: [
        { 'prescriptionInfo.type': regex },
        { 'clinicalContext.diagnosis': regex },
        { 'prescriptionInfo.notes': regex },
        { 'medications.dosage.instructions': regex }
      ]
    })
      //.populate('prescriber', 'name')
      .populate('medications.medication');
  }

  async exportPrescriptionAsPDF(id) {
    const prescription = await this.getPrescriptionById(id);
    if (!prescription) {
      throw new Error('Prescription not found');
    }
    const responseConsultation = await axios.get(`http://localhost:8003/api/consultations/${prescription.consultation}`);
    const responsePatient = await axios.get(`http://localhost:8002/api/patients/${responseConsultation.data.patientId}`);
    const patientName = `${responsePatient.data.firstName} ${responsePatient.data.lastName}`;
    //const patientEmail = responsePatient.data.email;
const patientEmail = 'rouayouneb0@gmail.com';
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({
          layout: 'landscape',
          size: [130 * 2.83465, 210 * 2.83465]
        });

        const buffers = [];
        doc.on('data', buffers.push.bind(buffers));
        doc.on('end', async () => {
          try {
            const pdfBuffer = Buffer.concat(buffers);

            // Chemin de stockage absolu correct
            const storageBase = path.resolve(__dirname, '../../storage/prescription');
            const prescriptionFolder = path.join(storageBase, id);

            // Créer le dossier s'il n'existe pas
            if (!fs.existsSync(prescriptionFolder)) {
              fs.mkdirSync(prescriptionFolder, { recursive: true });
            }

            const filename = `prescription-${id}.pdf`;
            const filePath = path.join(prescriptionFolder, filename);

            // Sauvegarder le fichier
            fs.writeFileSync(filePath, pdfBuffer);

            // Mettre à jour la prescription avec le chemin relatif
            await Prescription.findByIdAndUpdate(
              id,
              { pdfPath: `/prescriptions/${id}/${filename}` },
              { runValidators: false }
            );

            try {
              await EmailService.sendPrescriptionEmail(
                patientEmail,
                patientName,
                id,
                filePath
              );
              console.log('PDF saved and email sent successfully');
              resolve(pdfBuffer);
            } catch (emailError) {
              console.error('Email sending failed:', emailError.message);
              // On rejette seulement si le PDF n'a pas pu être sauvegardé
              // Ici on résoud quand même car le PDF est sauvegardé
              resolve(pdfBuffer);
            }
          } catch (saveError) {
            reject(saveError);
          }
        });

        this._generatePDFContent(doc, prescription, patientName);
        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }


  _generatePDFContent(doc, prescription, patientName) {
    const mmToPoint = 2.83465;
    const pageWidth = 210 * mmToPoint;
    const pageHeight = 110 * mmToPoint;

    const margin = 10 * mmToPoint;
    const leftColWidth = 55 * mmToPoint;
    const rightColWidth = pageWidth - leftColWidth - 2 * margin;
    const lineHeight = 5 * mmToPoint;

    const blueColor = '#1155cc';
    const darkBlue = '#0d47a1';
    const grayColor = '#757575';

    // Cadre gauche
    doc.rect(margin, margin, leftColWidth, pageHeight - 2 * margin)
      .fill(blueColor);

    doc.fillColor('#ffffff')
      .font('Helvetica-Bold')
      .fontSize(12)
      .text('Dr CHAFI Sabeur', margin + 5, margin + 10, {
        width: leftColWidth - 10,
        align: 'center'
      });

    doc.fillColor('#ffffff') // Blanc
      .font('Helvetica')    // Police normale (pas bold)
      .fontSize(11)         // Taille 11
      .text('Médecine Générale', margin + 5, margin + 30, {
        width: leftColWidth - 10,
        align: 'center'
      })
      .text('Av. H. Bourguiba', margin + 5, margin + 40, {
        width: leftColWidth - 10,
        align: 'center'
      })
      .text('Zéramdine 5040', margin + 5, margin + 50, {
        width: leftColWidth - 10,
        align: 'center'
      });
    doc.fontSize(10)
      .text('GSM: 97 498 410', margin + 5, margin + 90)
      .text('Tél.: 73 576 069', margin + 5, margin + 100)
      .text('Fax: 73 576 478', margin + 5, margin + 110)
      .text('roua@yahoo.fr', margin + 5, margin + 120, { width: leftColWidth - 10 });

    // C.C et I.U
    doc.rect(margin + 5, pageHeight - margin - 25, leftColWidth - 10, 10)
      .fill('#ffffff')
      .fillColor(darkBlue)
      .fontSize(7)
      .text('C.C: 1/89888/64', margin + 10, pageHeight - margin - 23, { width: leftColWidth - 20 });

    doc.rect(margin + 5, pageHeight - margin - 12, leftColWidth - 10, 10)
      .fill('#ffffff')
      .fillColor(grayColor)
      .text('I.U:', margin + 10, pageHeight - margin - 10, { width: leftColWidth - 20 });

    // Partie droite
    const rightColX = margin + leftColWidth + 10;

    doc.fillColor(darkBlue)
      .fontSize(9)
      .text('Zéramdine, le 28/04/2025', rightColX + 100, margin, {
        width: rightColWidth - 100,
        align: 'right'
      })
      .font('Helvetica-Bold')
      .text(`patient: ${patientName}`, rightColX + 100, margin + 12, {
        width: rightColWidth - 100,
        align: 'right'
      });

    doc.strokeColor('#dddddd')
      .moveTo(rightColX, margin + 30)
      .lineTo(pageWidth - margin, margin + 30)
      .stroke();

    doc.fillColor(darkBlue)
      .fontSize(12)
      .text('Médications:', rightColX, margin + 3);

    // Liste médicaments
// Dans _generatePDFContent - partie médicaments modifiée

// Liste médicaments - VERSION MODIFIÉE
let currentY = margin + 55;
prescription.medications.forEach(med => {
  let medicationName = '';
  let medicationStrength = '';
  
  // ✅ CAS 1: Médicament de la base de données
  if (med.medication?.identification) {
    medicationName = med.medication.identification.name;
    medicationStrength = med.dosage.strength;
  }
  // ✅ CAS 2: Médicament libre
  else if (med.customMedication?.name) {
    medicationName = med.customMedication.name;
    medicationStrength = med.dosage.strength || '';
  }
  
  // Afficher seulement si on a un nom
  if (medicationName) {
    doc.fillColor('#000000')
      .font('Helvetica-Bold')
      .fontSize(11)
      .text(`- ${medicationName}${medicationStrength ? ` (${medicationStrength})` : ''}`, rightColX, currentY, {
        width: rightColWidth
      });
    currentY += lineHeight;

    doc.font('Helvetica')
      .fontSize(10)
      .text(`Posologie: ${med.dosage.frequency} pendant ${med.dosage.duration}`, rightColX + 5, currentY);
    currentY += lineHeight;

    doc.text(`Instructions: ${med.dosage.instructions}`, rightColX + 5, currentY);
    currentY += lineHeight * 1.5;
  }
});

    // Signature
    doc.strokeColor('#000000')
      .moveTo(pageWidth - margin - 60, pageHeight - margin - 15)
      .lineTo(pageWidth - margin, pageHeight - margin - 15)
      .stroke();

    doc.fillColor(grayColor)
      .fontSize(7)
      .text('Signature et cachet', pageWidth - margin - 60, pageHeight - margin - 12, {
        width: 60,
        align: 'center'
      });
  }










async getPrescriptionsByConsultation(consultationId) {
  try {
    return await Prescription.find({ consultation: consultationId })
      .populate('medications.medication')
      .sort({ 'prescriptionInfo.date': -1 });
  } catch (error) {
    logger.error(`Error fetching prescriptions for consultation ${consultationId}: ${error.message}`);
    throw error;
  }
}


}
// Nouvelle méthode à ajouter dans le service









module.exports = new PrescriptionService();

